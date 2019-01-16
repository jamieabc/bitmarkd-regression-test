gem "openssl"
require "openssl"
require "socket"
require "rspec"
require "pry"
require_relative "cli"
require_relative "bitcoin"

class Bitmarkd
  attr_reader :cli_conf, :password, :default_identity, :bm_num, :port, :ip, :data_dir,
    :data_backup_dir, :home_path, :go_path, :go_bin_path, :name
  attr_accessor :prev_cmd, :asset_name, :asset_quantity, :asset_meta, :response,
    :issued, :tx_id, :pay_tx_id, :fingerprint, :provenance, :payments

  include Cli

  def initialize(bm_num:, port:)
    @bm_num = bm_num
    @name = "bitmarkd#{@bm_num}"
    @port = port
    @ip = is_os_freebsd ? "172.16.23.113" : "127.0.0.1"
    @data_dir = "data"
    @data_backup_dir = "data-backup"
    @home_path = ENV["HOME"]
    @go_path = ENV["GOPATH"]
    @go_bin_path = "#{go_path}/bin"
    init_cli
  end

  def status(hsh = {})
    raise "#{name} stopped" if stopped?
    identity = hsh.key?(:identity) ? hsh[:identity] : default_identity
    cmd = bm_status_cmd(identity)

    resp = `#{cmd}`
    if resp.empty? || resp.include?("error")
      puts "status error response: #{resp}"
      return ""
    end

    JSON.parse(resp)
  end

  def normal?
    "normal".casecmp?(status["mode"])
  end

  def bm_base_cmd
    "#{bm_exec} --config-file='#{name}.conf'"
  end

  def truncate_chain_to_block(blk_num)
    cd_cmd = enter_dir_cmd
    del_cmd = "#{bm_base_cmd} delete-down #{blk_num}"

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
    sleep self.class.stop_time
    terminate(true)
  end

  def terminate(force)
    cmd = "pgrep -f #{name} | xargs kill"
    cmd << " -SIGKILL" if force == true
    `#{cmd}`
  end

  def stopped?
    `pgrep -f #{name}`.empty?
  end

  def enter_dir_cmd
    "cd #{path}"
  end

  def start_cmd
    "#{bm_base_cmd} start >/dev/null 2>&1"
  end

  def wait_status(exp_mode)
    raise "#{name} stopped" if stopped?
    slept_time = 0
    resp = nil

    # for bitmarkd1 and bitmarkd2, it's the starting process, no need to wait it
    return if [1, 2].include?(bm_num)

    while slept_time < self.class.start_time
      resp = status
      sleep self.class.sleep_interval if resp.empty?
      mode = status["mode"]
      break if exp_mode.casecmp?(mode)
      slept_time += self.class.sleep_interval
      sleep self.class.sleep_interval
    end

    puts "#{name} cli result: #{JSON.parse(resp)}"

    unless exp_mode.casecmp?(mode)
      raise "wait #{slept_time} seconds, mode #{mode} differs expected #{exp_mode}"
    end
  end

  def start
    puts "starting #{name}..."
    puts "#{name} is already started..." unless stopped?

    if stopped?
      bg_start_cmd = "nohup #{start_cmd} &"
      cmd = "#{enter_dir_cmd}; #{bg_start_cmd}"

      `#{cmd}`
    end

    wait_status("normal")
  end

  def double_quote_str(str)
    "\"#{str}\""
  end

  def clean_bitmarkd_data
    puts "clear #{name} data..."
    raise "#{name} not stopped" unless stopped?
    cmd = "[ -d #{path}/data ] && rm -r #{path}/data"

    `#{cmd}`
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
    sleep self.class.stop_time

    cmd = double_quote_str("#{dump_db_cmd} T")

    result = `#{cmd} 2>&1`
    start
    result
  end

  def remove_unwanted_data(str)
    truncate_length = str.index("\n") + 1
    str[truncate_length..(-1 * truncate_length - 1)]
  end

  def check_backup_data_exist?
    cmd = "ls #{path}/#{data_backup_dir}"

    result = `#{cmd}`

    raise "#{backup_dir} not exist" if result.include?("No such file or directory")
  end

  def block_height
    status["blocks"]
  end

  def change_data_to_backup
    check_backup_data_exist?

    cd_cmd = enter_dir_cmd
    rm_cmd = "rm -r #{data_dir}"
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
    ssl = open_ssl_socket
    ssl.puts "{\"id\":\"1\",\"method\":\"Assets.Get\",\"params\":[{\"fingerprints\": [\"#{fingerprint}\"]}]}"
    self.issued = JSON.parse(ssl.gets)
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

      sleep Bitmarkd.sleep_interval
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
    iteration * Bitmarkd.sleep_interval >= Bitmarkd.tx_limit_time
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
    10
  end

  def self.start_time
    180
  end

  def self.stop_time
    5
  end

  def self.genesis_blk
    1
  end
end
