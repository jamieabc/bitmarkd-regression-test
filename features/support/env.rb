def setup_variables
  @cli_identity = "regression test user"
  @me = @cli_identity
  @cli_password = "12345678"
  @cli_file = "cli.conf"
  @wallet_file = "wallet.conf"
  @cli_network = "local"
  @cli_description = "test"
  @pay_tx_id = nil
  @provenance = nil
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
