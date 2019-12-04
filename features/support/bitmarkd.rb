require "openssl"
require "socket"
require "rspec"
require "pry"
require "net/http"
require 'fileutils'
require "awesome_print"

require_relative "helper"
require_relative "cli"
require_relative "bitcoin"
require_relative 'variables/env'
require_all('network')
require_all('variables')

class Bitmarkd
  attr_reader :cli_conf, :password, :default_identity, :bitmarkd_index, :port, :ip,
              :name, :asset_name, :asset_quantity, :asset_meta, :identity, :network,
              :rpc

  attr_accessor :prev_cmd, :response, :issued, :tx_id, :pay_tx_id, :fingerprint,
                :provenance, :payments, :share_amount, :share_id, :share_info

  include Cli
  include Variables::Env
  include Variables::Bitmarkd

  def initialize(bitmarkd_index:)
    init_bitmarkd(bitmarkd_index)
    init_network(bitmarkd_index)
    init_cli
  end

  def status
    err_return = {"mode" => "not started"}
    return err_return if stopped?

    resp = rpc.status
    if resp == '' || !resp.is_a?(Net::HTTPSuccess)
      puts "status error response: #{resp}"
      return err_return
    end

    self.response = JSON.parse(resp.body)
  end

  def normal?
    "normal".casecmp?(status["mode"])
  end

  def bm_base_cmd
    "#{bitmarkd_bin_path} --config-file='#{name}.conf'"
  end

  def truncate_to_block(number)
    puts "truncate #{name} block number to #{number}"

    cd_cmd = enter_dir_cmd
    del_cmd = "#{bm_base_cmd} delete-down #{number + 1}"
    `#{cd_cmd}; #{del_cmd}`
  end

  # bitmarkd could possibly not respond to kill command
  # the lock behavior happens at listener.go, I plan to solve it in the
  # future, but as now, when it happens, use "kill -SIGKILL" to force terminate
  def stop
    puts "#{name} current status: #{status['mode']}, stopping..."
    return if stopped?

    terminate(false)
    return if stopped?

    sleep Variables::Timing.check_interval
    terminate(true)

    raise "cannot stop #{name}" unless stopped?
  end

  def terminate(force)
    cmd = "pgrep -f #{name} | xargs kill"
    cmd << " -SIGKILL" if force == true
    `#{cmd}`
  end

  def stopped?
    # use "bitmarkd3.conf" as format because I could show log at the same time.
    # it would be safer to test for bitmarkd3.conf file rather than bitmarkd3
    # which might count in tail command: tail -f .../bitmarkd3/log/...
    `pgrep -f #{name}.conf`.empty?
  end

  def enter_dir_cmd
    "cd #{data_path}"
  end

  def start_cmd
    "#{bm_base_cmd} start >/dev/null 2>&1"
  end

  def start_bg_cmd
    "nohup #{start_cmd} &"
  end

  def wait_status(exp_mode)
    slept_time = 0
    sleep_itrv = Variables::Timing.check_interval
    max_sleep_time = Variables::Timing.start_interval
    resp = nil

    # for bitmarkd2, wait longer time for both bitmarkd 1 & 2 to start
    return if bitmarkd_index == 1

    if bitmarkd_index == 2
      sleep max_sleep_time
      return
    end

    while slept_time < max_sleep_time
      return false if stopped?

      sleep sleep_itrv
      slept_time += sleep_itrv
      resp = status
      next if resp.empty?

      mode = status["mode"]
      break if exp_mode.casecmp?(mode)
    end
    puts "#{name} cli result:"
    ap resp
    unless exp_mode.casecmp?(mode)
      raise "#{name} waits #{slept_time} seconds, " \
            "mode #{mode} differs from expected #{exp_mode}"
    end
    true
  end

  def status?(mode)
    return false if stopped?

    mode.downcase == status["mode"].downcase
  end

  def check_mode(mode)
    raise "#{name} not started..." if stopped?

    slept_time = 0
    while slept_time <= Variables::Timing.start_interval
      return if status?(mode)

      sleep Variables::Timing.check_interval
      slept_time += Variables::Timing.check_interval
    end
    raise "#{name} cannot into #{mode} mode"
  end

  def start
    puts "starting #{name}..."
    return unless stopped?

    `#{enter_dir_cmd}; #{start_bg_cmd}`
    sleep Variables::Timing.check_interval
    raise "cannot start #{name}" if stopped?
  end

  def double_quote_str(str)
    "\"#{str}\""
  end

  def remove_file(file_path)
    File.delete(file_path) if File.exist?(file_path)
  end

  def remove_dir(dir_path)
    FileUtils.rm_r(dir_path) if File.directory?(dir_path)
  end

  def clear_data
    raise "#{name} not stopped" unless stopped?

    puts "delete #{name} data directory..."
    remove_dir("#{data_path}/data")
  end

  def clear_reservoir_cache
    raise "#{name} not stopped" unless stopped?

    puts "delete #{name} cache file..."
    remove_file("#{data_path}/#{reservoir_cache_file}")
  end

  def clear_peer_cache
    raise "#{name} not stopped" unless stopped?

    puts "delete #{name} peer file..."
    remove_file("#{data_path}/#{peer_cache_file}")
  end

  def remove_unwanted_data(str)
    truncate_length = str.index("\n") + 1
    str[truncate_length..(-1 * truncate_length - 1)]
  end

  def height
    status["block"]["count"]["local"].to_i
  end

  def open_ssl_socket
    socket = TCPSocket.new(ip, port.node)
    ssl = OpenSSL::SSL::SSLSocket.new(socket)
    ssl.sync_close = true
    ssl.connect
    ssl
  end

  def asset_info
    request_body = {
      id: 1,
      method: "Assets.Get",
      params: [{fingerprints: [fingerprint.to_s]}]
    }.to_json
    resp = rpc.asset_info(request_body)
    raise "RCP asset get response error: #{resp.body}" unless resp.is_a?(Net::HTTPSuccess)

    self.issued = JSON.parse(resp.body)
  end

  def same_blockchain?(benchmark)
    own_status = status
    other_status = benchmark.status

    return true if own_status["hash"] == other_status["hash"]

    false
  end

  # TODO: consider change this method into wait_tx_confirmed, cause currently no other
  # status will be waited. In this way, exp_status can be removed, and id can be made
  # default to instance method "id"
  def wait_tx_status(id:, exp_status:)
    # mine some blocks, make sure transfer is confirmed
    BTC.mine
    puts "wait tx #{id} become #{exp_status}..."
    result = check_tx_status(id: id, exp_status: exp_status)

    raise "issue #{id} status not #{exp_status}" unless result.casecmp?(exp_status)

    asset_info
  end

  def check_tx_status(id:, exp_status:)
    start = Time.now
    iterate_count = 0
    json = nil

    loop do
      json = JSON.parse(tx_status(id))
      break if tx_limit_exceed? iterate_count

      break if json && json['status'] && json['status'].casecmp?(exp_status)

      sleep Variables::Timing.check_interval
      iterate_count += 1
    end

    puts "takes #{Time.now - start} seconds for a transfer, limit: #{Variables::Timing.tx_limit} seconds"
    json['status']
  end

  def tx_limit_exceed?(iteration)
    iteration * Variables::Timing.check_interval >= Variables::Timing.tx_limit
  end

  def provenance_owner(idx:)
    # make sure provenance is long enough
    if provenance.length <= idx
      puts "provenance: #{provenance}, target element index: #{idx}"
      raise "Error, provenance is not long enough"
    end
    provenance[idx]["_IDENTITY"]
  end

  def provenance_history
    resp = query_provenance(pay_tx_id)
    self.provenance = JSON.parse(resp)["data"]
  end

  # below are class methods

  def self.start_all(*bms)
    bms.each(&:start)
  end

  def self.normal(*bms)
    bms.each do |bm|
      bm.check_mode("normal")
    end
  end

  private

  def init_bitmarkd(bitmarkd_index)
    @bitmarkd_index = bitmarkd_index
    @name = "bitmarkd#{bitmarkd_index}"
  end

  def init_network(bitmarkd_index)
    @port = Network::Port.new(bitmarkd_index)
    @ip = Network::IP.new.ip
    @rpc = Network::RPC.new(ip: ip, port: port.rpc)
  end
end
