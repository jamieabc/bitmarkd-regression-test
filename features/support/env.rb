require "rspec"

def setup_variables
  @cli_identity = "regression test user"
  @me = @cli_identity

  @cli_password = "12345678"

  @cli_file_normal = "cli3.conf"
  @cli_file_backup = "cli4.conf"
  switch_cli_file_to_normal

  @wallet_file = "wallet.conf"

  @cli_network = "local"
  @cli_description = "test"

  @cli_result = nil

  @pay_tx_id = nil
  @provenance = nil

  @os = `uname`.gsub(/\n/, "")
  @home_path = ENV["HOME"]
  @go_path = ENV["GOPATH"]
  @go_bin_path = @go_path + "/bin"

  reset_issue_args
end

def reset_issue_args
  @asset_name = nil
  @asset_meta = {}
  @fingerprint = nil
end

def host_port
  "2330"
end

def host_ip
  if is_os_freebsd
    "172.16.23.113"
  else
    "127.0.0.1"
  end
end

def cli_url
  "#{host_ip}:#{host_port}"
end

def switch_cli_file_to_normal
  switch_cli_file("normal")
end

def switch_cli_file_to_backup
  switch_cli_file("backup")
end

def switch_cli_file(mode)
  @cli_file = (mode == "normal") ? @cli_file_normal : @cli_file_backup
end

def is_os_freebsd
  @os == "FreeBSD"
end

def data_backup_dir
  "data-backup"
end

def data_dir
  "data"
end

def wait_tx_limit_sec
  60 * 10
end

def sleep_interval_sec
  10
end

# by experience, it takes 5 seconds for bitmarkd to stop
def bitmarkd_stop_time_sec
  5
end

# by experience, it takes 120 seconds for bitmarkd start into normal mode
def bitmarkd_start_time_sec
  120
end
