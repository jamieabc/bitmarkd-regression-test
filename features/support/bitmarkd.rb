def get_bitmarkd_status(config:, identity:)
  cmd = cli_bitmarkd_status_cmd(config: config, identity: identity)

  puts "cli cmd: #{cmd}"

  @cli_result = `#{cmd}`
  if @cli_result.empty? || @cli_result.include?("error")
    puts "cli error result: #{@cli_result}"
    return ""
  end

  JSON.parse(@cli_result)
end

# def delete_bitmarkd_to_same_block_height(bm_number)
def truncate_bitmarkd_to_consistent_chain_length(bm_number)
  status = get_bitmarkd_status(config: @cli_file_normal, identity: @cli_identity)
  block_height = status["blocks"]
  cd_cmd = enter_bitmarkd_dir_cmd bm_number
  del_cmd = delete_bitmarkd_block_to_cmd(
    block_number: block_height,
    bitmarkd_number: bm_number,
  )
  `#{cd_cmd}; #{del_cmd}`
end

# bitmarkd could possibly not respond to kill command
# the lock behavior happens at listener.go, I plan to solve it in the
# future, but as now, when it happens, use "kill -SIGKILL" to force terminate
def stop_bitmarkd(bitmarkd_number)
  kill_process(name: "bitmarkd#{bitmarkd_number}", force: false)
  return if bitmarkd_stopped? bitmarkd_number
  sleep bitmarkd_stop_time_sec
  kill_process(name: "bitmarkd#{bitmarkd_number}", force: true)
end

def kill_process(name:, force:)
  cmd = "pgrep -f #{name} | xargs kill"
  cmd << " -SIGKILL" if force == true
  `#{cmd}`
end

def bitmarkd_stopped?(number)
  `pgrep -f bitmarkd#{number}`.empty?
end

def enter_bitmarkd_dir_cmd(bitmarkd_number)
  "cd #{bitmarkd_path bitmarkd_number}"
end

def delete_bitmarkd_block_to_cmd(block_number:, bitmarkd_number:)
  "#{bitmarkd_executable} --config-file='bitmarkd#{bitmarkd_number} \
  delete-down #{block_number}"
end

def start_bitmarkd_cmd(bitmarkd_number)
  "#{bitmarkd_executable} --config-file='bitmarkd#{bitmarkd_number}.conf' \
  start >/dev/null 2>&1"
end

def wait_until_bitmarkd_status(exp_mode)
  puts "sleep #{bitmarkd_start_time_sec} seconds..."
  sleep bitmarkd_start_time_sec

  status = get_bitmarkd_status(
    config: @cli_file_normal,
    identity: @cli_identity,
  )
  mode = status["mode"]

  puts "cli result: #{@cli_result}"

  raise "bitmarkd mode #{mode} different from #{exp_mode}" unless exp_mode.casecmp?(mode)
end

def get_bitmarkd_process_status(bitmarkd_number)
  "pgrep -f bitmarkd#{bitmarkd_number}"
end

def start_bitmarkd(bitmarkd_number)
  # return bitmarkd already started
  return unless bitmarkd_stopped?(bitmarkd_number)

  start_cmd = start_bitmarkd_cmd(bitmarkd_number)
  bg_start_cmd = "nohup #{start_cmd} &"
  cmd = "#{enter_bitmarkd_dir_cmd(bitmarkd_number)}; #{bg_start_cmd}"

  `#{cmd}`
end

def double_quote_str(str)
  "\"#{str}\""
end

def clean_bitmarkd_data(bitmarkd_number)
  path = bitmarkd_path(bitmarkd_number)
  cmd = "[ -d #{path}/data ] && rm -r #{path}/data"

  `#{cmd}`
end

def bitmarkd_path(bitmarkd_number)
  "#{@home_path}/.config/bitmarkd#{bitmarkd_number}"
end

# should use GOPATH, but it will be replaced by host computer
def bitmarkd_executable
  "#{@go_bin_path}/bitmarkd"
end

def dumpdb_exec
  "#{@go_bin_path}/bitmark-dumpdb"
end

def dump_db_cmd(bitmarkd_number)
  bm_path = bitmarkd_path(bitmarkd_number)
  file_path = "#{bm_path}/data/local"
  "#{dumpdb_exec} --file=#{file_path}"
end

def dump_db_tx(bitmarkd_number)
  stop_bitmarkd(bitmarkd_number)

  # wait 5 seconds for bitmarkd to stop
  sleep bitmarkd_stop_time_sec

  cmd = double_quote_str("#{dump_db_cmd(bitmarkd_number)} T")

  result = `#{cmd} 2>&1`

  start_bitmarkd(bitmarkd_number)

  result
end

def same_db_record?(data1, data2)
  db1 = remove_unwanted_data(data1)
  db2 = remove_unwanted_data(data2)
  db1 == db2
end

def remove_unwanted_data(str)
  truncate_length = str.index("\n") + 1
  str[truncate_length..(-1 * truncate_length - 1)]
end

def check_backup_data_exist?(bitmarkd_number)
  cmd = "ls #{bitmarkd_path bitmarkd_number}/#{data_backup_dir}"

  result = `#{cmd}`

  raise "#{backup_dir} not exist" if result.include?("No such file or directory")
end

def change_data_to_backup(bitmarkd_number)
  check_backup_data_exist?(bitmarkd_number)

  cd_cmd = enter_bitmarkd_dir_cmd(bitmarkd_number)
  rm_cmd = "rm -r #{data_dir}"
  change_cmd = "cp -r #{data_backup_dir} #{data_dir}"

  cmd = cd_cmd + "; " + rm_cmd + "; " + change_cmd

  puts "cmd: #{cmd}"

  puts "restore bitmarkd#{bitmarkd_number}, #{data_backup_dir} to #{data_dir}"
  `#{cmd}`
end

def same_blockchain?(benchmark, new)
  benchmark_db = dump_db_tx(benchmark)
  raise "Error empty result of bitamarkd #{benchmark} dump" if benchmark_db.empty?

  new_db = dump_db_tx(new)
  raise "Error empty result of bitamarkd #{new} dump" if new_db.empty?

  same_db_record?(benchmark_db, new_db)
end
