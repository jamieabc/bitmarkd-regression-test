def cli_default_user_cmd
  cli_user_cmd(user: @cli_identity, password: @cli_password)
  # "#{cli_base_cmd} -i '#{@cli_identity}' -p #{@cli_password}"
end

def cli_user_cmd(user:, password:)
  "#{cli_base_cmd} -i '#{user}' -p '#{password}'"
end

def cli_base_cmd
  "bitmark-cli -c #{@cli_file}"
end

def cli_setup_command
  "#{cli_default_user_cmd} setup #{cli_setup_args}"
end

def cli_get_users
  resp = JSON.parse(`#{cli_default_user_cmd} info`)
  resp["identities"].map { |i| i["name"] }
end

def do_issue(again: false)
  @cli_result = nil
  # generate new issue or use previous one
  if again && !@prev_cli_cmd.nil?
    cmd = @prev_cli_cmd
    # clear previous existing result
  else
    cmd = cli_create_issue
    @prev_cli_cmd = cli_create_issue
  end

  puts "issue command: #{cmd}"
  @cli_result = `#{cmd}`
  puts "cli issue with response: #{@cli_result}"
  raise "Issue failed with message #{@cli_result}" if !@cli_result
end

def cli_create_issue
  "#{cli_default_user_cmd} create #{cli_create_issue_args} 2>&1"
end

def cli_get_tx_status(id)
  `#{cli_default_user_cmd} status #{tx_id_args id}`
end

def cli_get_provenance(id)
  result = `#{cli_default_user_cmd} provenance #{tx_id_args id}`
end
