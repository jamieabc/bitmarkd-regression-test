require "pry"

Given(/^I have bitmark-cli config file$/) do
  setup_variables
  # generate only if config file not exist
  unless File.exist? @cli_file
    result = `#{cli_setup_command}`

    # check if config file create successfully
    if result.include? "error"
      raise "generate bitmark-cli conf fail with message: #{result}"
    end
  end
end

Given(/^I have a friend "(.*)" with bitmark account$/) do |friend|
  # create user if not exist
  unless user_exist? friend
    create_new_user friend
  end
end

Given(/^latest wallet balance is able to do transfer$/) do
  if File.exist? @wallet_file
    resp = `#{wallet_sync_balance}`
    balance = resp.split("\n")
      .select { |str| str.include? "Balance:" }.first
      .split(" ")[1].to_i
    expect(balance).to be > transfer_fee
  else
    raise "Error: wallet config file #{@wallet_file} not exist"
  end
end

def user_exist?(name)
  users = cli_get_users
  users.include? name
end

# default password set to 12345678
def create_new_user(name)
  puts `#{cli_base_cmd} -i #{name} -p #{@cli_password} add -d #{name} 2>&1`
end

def remove_config
  File.delete @cli_file
end
