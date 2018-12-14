def get_bitmarkd_status
  # only show cli command once
  if @cli_result.nil?
    puts "cli cmd: #{cli_default_user_cmd} bitmarkInfo"
  end

  @cli_result = `#{cli_default_user_cmd} bitmarkInfo`
  json = JSON.parse(@cli_result)
  json["mode"]
end

def stop_bitmarkd(bitmarkd_number)
  cmd = "pgrep -f bitmarkd#{bitmarkd_number} | xargs kill"

  if !is_os_freebsd
    cmd = ssh_cmd + " " + double_quote_str(cmd)
  end

  @ssh_result = `#{cmd}`
end

def enter_bitmarkd_dir_cmd(bitmarkd_number)
  "cd #{bitmarkd_path bitmarkd_number}"
end

def start_bitmarkd_cmd(bitmarkd_number)
  "#{bitmarkd_executable} --config-file='bitmarkd#{bitmarkd_number}.conf' start >/dev/null 2>&1"
end

def wait_until_bitmarkd_status(exp_status)
  status = get_bitmarkd_status
  start = Time.now

  # wait at most 100 seconds, each time for 10 seconds
  iterate_count = 10

  loop do
    status = get_bitmarkd_status
    break if exp_status == status || iterate_count < 0
    iterate_count -= 1
    sleep 10
  end

  finish = Time.now

  puts "cli result: #{@cli_result}"

  if status != exp_status
    raise "bitmarkd cannot become #{exp_status} after #{finish - start} seconds..."
  else
    puts "wait bitmarkd become #{exp_status} takes #{finish - start} seconds"
  end
end

def get_bitmarkd_process_status(bitmarkd_number)
  "pgrep -f bitmarkd#{bitmarkd_number}"
end

def start_bitmarkd(bitmarkd_number)
  start_cmd = start_bitmarkd_cmd bitmarkd_number
  bg_start_cmd = "nohup #{start_cmd} &"
  cmd = enter_bitmarkd_dir_cmd(bitmarkd_number) + "; " + bg_start_cmd

  if !is_os_freebsd
    cmd = ssh_cmd + " " + double_quote_str(cmd)
  end

  @ssh_result = `#{cmd}`
end

def double_quote_str(str)
  "\"#{str}\""
end

def clean_bitmarkd_data(bitmarkd_number)
  path = bitmarkd_path bitmarkd_number
  cmd = "[ -d #{path}/data ] && rm -r #{path}/data"

  if !is_os_freebsd
    cmd = ssh_cmd + " " + double_quote_str(cmd)
  end

  @ssh_result = `#{cmd}`
end

def bitmarkd_path(bitmarkd_number)
  if is_os_freebsd
    "~/.config/bitmarkd#{bitmarkd_number}"
  else
    ".config/bitmarkd#{bitmarkd_number}"
  end
end

# should use GOPATH, but it will be replaced by host computer
def bitmarkd_executable
  "#{go_bin_path}/bitmarkd"
end

def dumpdb_exec
  "#{go_bin_path}/bitmark-dumpdb"
end

def go_bin_path
  "~/gocode/bin"
end

# by experience, it takes 30 seconds for bitmarkd to start
def bitmarkd_start_time_sec
  30
end

def dump_db_cmd(bitmarkd_number)
  bm_path = bitmarkd_path bitmarkd_number
  file_path = bm_path + "/data/local"
  "#{dumpdb_exec} --file=#{file_path}"
end

def dump_db_tx(bitmarkd_number)
  stop_bitmarkd bitmarkd_number

  # wait 3 seconds for bitmarkd to stop
  sleep 3

  cmd = double_quote_str(dump_db_cmd(bitmarkd_number) + " T")

  if !is_os_freebsd
    cmd = ssh_cmd + " " + cmd
  end

  result = `#{cmd}`

  start_bitmarkd bitmarkd_number

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

  if !is_os_freebsd
    cmd = ssh_cmd + " " + double_quote_str(cmd)
  end

  result = `#{cmd}`

  raise "#{backup_dir} not exist" if result.include? "No such file or directory"
end

def change_data_to_backup(bitmarkd_number)
  check_backup_data_exist? bitmarkd_number

  cd_cmd = enter_bitmarkd_dir_cmd bitmarkd_number
  rm_cmd = "rm -r data"
  change_cmd = "cp -r #{data_backup_dir} data"

  cmd = cd_cmd + "; " + rm_cmd + "; " + change_cmd

  if !is_os_freebsd
    cmd = ssh_cmd + " " + double_quote_str(cmd)
  end
  puts "cmd: #{cmd}"

  puts "restore bitmarkd#{bitmarkd_number} previous #{data_backup_dir} directory to data"
  @ssh_result = `#{cmd}`
end

def same_blockchain?(benchmark, new)
  benchmark_db = dump_db_tx(benchmark)
  raise "Error empty result of bitamarkd #{benchmark} dump" if benchmark_db.empty?

  new_db = dump_db_tx(new)
  raise "Error empty result of bitamarkd #{new} dump" if new_db.empty?

  same_db_record?(benchmark_db, new_db)
end
