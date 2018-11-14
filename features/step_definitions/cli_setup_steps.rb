Given(/^I am a user of bitmark-cli$/) do
  setup_variables
  # generate only if config file not exist
  if !File.exist? cli_file
    result = `#{cli_setup_command}`

    # check if config file create successfully
    if result.include? 'error'
      raise "generate bitmark-cli conf fail with message: #{result}"
    end
  end
end

def host_ip
  "172.16.23.113"
end

def host_port
  "2230"
end

def cli_url
  "#{host_ip}:#{host_port}"
end

def desc
  "test"
end

def identity
  "regression test user"
end

def password
  "12345678"
end

def cli_file
  "cli.conf"
end

def network
  "local"
end

def setup_variables
  @cli_identity = identity
  @cli_password = password
  @cli_filename = cli_file
  @cli_network = network
  @cli_description = desc
end

def remove_config
  File.delete cli_file
end

def cli_base_command
  "bitmark-cli -c #{@cli_filename} -i '#{@cli_identity}' -p #{@cli_password}"
end

def cli_setup_args
  "-n #{@cli_network} -x #{cli_url} -d #{@cli_description}"
end

def cli_setup_command
  "#{cli_base_command} setup #{cli_setup_args}"
end
