require "openssl"
require "socket"
require "rspec"
require "pry"
require "net/http"
require_relative "cli"
require_relative "bitcoin"
require_relative "helper"

class Bitmarkd
  attr_reader :cli_conf, :password, :default_identity, :bm_num, :port, :ip, :data_dir,
    :data_backup_dir, :home_path, :go_path, :go_bin_path, :name, :rpc_port, :status_uri,
    :rpc_uri, :asset_name, :asset_quantity, :asset_meta, :identity

  attr_accessor :prev_cmd, :response, :issued, :tx_id, :pay_tx_id, :fingerprint,
    :provenance, :payments, :share_amount, :share_id, :share_info

  include Cli

  def initialize(bm_num:, port:)
    @bm_num = bm_num
    @name = "bitmarkd#{@bm_num}"
    @port = port
    @rpc_port = "2#{bm_num}31"
    @ip = is_os_freebsd ? "172.16.23.113" : "127.0.0.1"
    @status_uri = "/bitmarkd/details"
    @rpc_uri = "/bitmarkd/rpc"
    @data_dir = "data"
    @data_backup_dir = "data-backup"
    @home_path = ENV["HOME"]
    @go_path = ENV["GOPATH"]
    @go_bin_path = "#{go_path}/bin"
    init_cli
  end

  def create_http
    http = Net::HTTP.new(ip, rpc_port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http
  end

  def empty_record?
    status["blocks"]["local"] == 1 && status["blocks"]["remote"] == 1
  end

  def status
    return "" if stopped?

    http = create_http
    begin
      resp = http.get(status_uri)
    rescue Exception => e
      puts "#{name} http not ready"
      return ""
    end

    unless resp.kind_of?(Net::HTTPSuccess)
      puts "status error response: #{resp.body}"
      return ""
    end

    self.response = JSON.parse(resp.body)
    response
  end

  def normal?
    "normal".casecmp?(status["mode"])
  end

  def bm_base_cmd
    "#{bm_exec} --config-file='#{name}.conf'"
  end

  def truncate_to_block(blk_num)
    puts "truncate #{name} block number to #{blk_num}"

    cd_cmd = enter_dir_cmd
    del_cmd = "#{bm_base_cmd} delete-down #{blk_num + 1}"
    `#{cd_cmd}; #{del_cmd}`
  end

  # bitmarkd could possibly not respond to kill command
  # the lock behavior happens at listener.go, I plan to solve it in the
  # future, but as now, when it happens, use "kill -SIGKILL" to force terminate
  def stop
    puts "stopping #{name}..."
    return if stopped?

    terminate(false)
    return if stopped?

    sleep self.class.stop_interval
    terminate(true)
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
    "cd #{path}"
  end

  def start_cmd
    "#{bm_base_cmd} start >/dev/null 2>&1"
  end

  def start_bg_cmd
    "nohup #{start_cmd} &"
  end

  def wait_status(exp_mode)
    slept_time = 0
    sleep_int = self.class.sleep_interval
    sleep_limit = self.class.start_interval
    resp = nil

    # for bitmarkd2, wait longer time for both bitmarkd 1 & 2 to start
    return if bm_num == 1

    if bm_num == 2
      sleep sleep_limit
      return
    end

    while slept_time < sleep_limit
      return false if stopped?

      sleep sleep_int
      slept_time += sleep_int
      resp = status
      next if resp.empty?
      mode = status["mode"]
      break if exp_mode.casecmp?(mode)
    end
    puts "#{name} cli result: #{resp}"
    unless exp_mode.casecmp?(mode)
      raise "#{name} waits #{slept_time} seconds, " \
            "mode #{mode} differs from expected #{exp_mode}"
    end
    true
  end

  def start
    puts "starting #{name}..."
    cmd = "#{enter_dir_cmd}; #{start_bg_cmd}"
    retry_cnt = 3

    while retry_cnt > 0
      if stopped?
        `#{cmd}`
      end

      return if wait_status("normal")
      retry_cnt -= 1
    end
    raise "#{name} cannot start..." if stopped?
  end

  def double_quote_str(str)
    "\"#{str}\""
  end

  def clear_data
    raise "#{name} not stopped" unless stopped?

    puts "delete #{name} data directory..."
    `[ -d #{path}/data ] && rm -r #{path}/data`
  end

  def clear_cache
    raise "#{name} not stopped" unless stopped?

    puts "delete #{name} cache file..."
    `[ -f #{path}/reservoir-local.cache ] && rm #{path}/reservoir-local.cache`
  end

  def path
    "#{@home_path}/.config/#{name}"
  end

  def bm_exec
    "#{@go_bin_path}/bitmarkd"
  end

  def dumpdb_exec
    "#{@go_bin_path}/bitmark-dumpdb"
  end

  def dump_db_cmd
    file_path = "#{path}/data/local"
    "#{dumpdb_exec} --file=#{file_path}"
  end

  def dump_db_tx
    stop

    # wait 5 seconds for bitmarkd to stop
    sleep self.class.stop_interval

    cmd = double_quote_str("#{dump_db_cmd} T")

    result = `#{cmd} 2>&1`
    start
    result
  end

  def remove_unwanted_data(str)
    truncate_length = str.index("\n") + 1
    str[truncate_length..(-1 * truncate_length - 1)]
  end

  def backup_exist?
    result = `ls #{path}/#{data_backup_dir}`
    return false if result.include?("No such file or directory")

    true
  end

  def block_height
    status["blocks"]["local"].to_i
  end

  def restore_backup
    return unless backup_exist?

    cd_cmd = enter_dir_cmd
    rm_cmd = "rm -rf #{data_dir}"
    change_cmd = "cp -r #{data_backup_dir} #{data_dir}"

    cmd = cd_cmd + "; " + rm_cmd + "; " + change_cmd

    puts "cmd: #{cmd}"

    puts "restore #{name}, #{data_backup_dir} to #{data_dir}"
    `#{cmd}`
  end

  def open_ssl_socket
    socket = TCPSocket.new(ip, port)
    ssl = OpenSSL::SSL::SSLSocket.new(socket)
    ssl.sync_close = true
    ssl.connect
    ssl
  end

  def issued_data
    http = create_http
    body = {
      "id" => 1,
      "method" => "Assets.Get",
      "params" => [
        {
          "fingerprints" => [
            "#{fingerprint}",
          ],
        },
      ],
    }.to_json
    resp = http.post(rpc_uri, body, "Content-Type" => "application/json")
    raise "RCP asset get response error: #{resp.body}" unless resp.kind_of?(Net::HTTPSuccess)
    self.issued = JSON.parse(resp.body)
  end

  def same_blockchain?(benchmark)
    benchmark_db = benchmark.dump_db_tx
    raise "Error empty result of bitamarkd #{benchmark} dump" if benchmark_db.empty?

    new_db = dump_db_tx
    raise "Error empty result of bitamarkd #{new} dump" if new_db.empty?

    same_db?(benchmark_db, new_db)
  end

  def same_db?(data1, data2)
    db1 = remove_unwanted_data(data1)
    db2 = remove_unwanted_data(data2)
    db1 == db2
  end

  # todo: consider change this method into wait_tx_confirmed, cause currently no other
  # satatus will be waited. In this way, exp_status can be removed, and id can be made
  # default to instance method "id"
  def wait_tx_status(id:, exp_status:)
    # mine some blocks, make sure transfer is confirmed
    BTC.mine
    puts "wait tx #{id} become #{exp_status}..."
    result = check_tx_status(id: id, exp_status: exp_status)

    raise "issue #{id} status not #{exp_status}" unless result.casecmp?(exp_status)

    issued_data
  end

  def check_tx_status(id:, exp_status:)
    # for i in 0..query_retry_count
    start = Time.now
    resp_status = nil
    iterate_count = 0
    tx_limit_exceed = false
    loop do
      json = JSON.parse(tx_status(id))
      iterate_count += 1
      if json && json["status"]
        resp_status = json["status"]
        tx_limit_exceed = tx_limit_exceed? iterate_count
        break if resp_status.casecmp?(exp_status) || tx_limit_exceed
      end

      sleep self.class.sleep_interval
    end
    finish = Time.now
    if tx_limit_exceed
      puts "time limit exceed"
    else
      puts "takes #{finish - start} seconds"
    end

    resp_status
  end

  def tx_limit_exceed?(iteration)
    iteration * self.class.sleep_interval >= self.class.tx_limit_time
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

  def self.sleep_interval
    5
  end

  def self.start_interval
    300
  end

  def self.stop_interval
    5
  end

  def self.genesis_blk
    1
  end

  def self.start_all(*bms)
    bms.each do |bm|
      bm.start
      sleep self.sleep_interval
    end
  end
end
