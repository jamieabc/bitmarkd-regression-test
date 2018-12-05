Given(/^I have bitmark-cli config file$/) do
  setup_variables
  # generate only if config file not exist
  if !File.exist? @cli_file
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

def setup_variables
  @cli_identity = 'regression test user'
  @cli_password = '12345678'
  @cli_file = 'cli.conf'
  @cli_network = 'local'
  @cli_description = 'test'
end

def remove_config
  File.delete @cli_file
end

def cli_base_command
  "bitmark-cli -c #{@cli_file} -i '#{@cli_identity}' -p #{@cli_password}"
end

def cli_setup_args
  "-n #{@cli_network} -x #{cli_url} -d #{@cli_description}"
end

def cli_setup_command
  "#{cli_base_command} setup #{cli_setup_args}"
end
