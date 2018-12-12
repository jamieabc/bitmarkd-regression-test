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
  @ssh_result = nil

  @pay_tx_id = nil
  @provenance = nil

  @os = `uname -a`.gsub(/\n/, "")
end

def host_port
  "2230"
end

def host_ip
  "172.16.23.113"
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
  if mode == "normal"
    @cli_file = @cli_file_normal if mode == "normal"
  else
    @cli_file = @cli_file_backup
  end
end

def is_os_freebsd
  @os == "FreeBSD"
end

# assume .ssh/config with settings of server freebuilder, no need to type pass phrase
def ssh_cmd
  "ssh free"
end
