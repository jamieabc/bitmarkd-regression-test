def cli_default_conf_cmd
  "#{cli_cmd config: @cli_file, identity: @cli_identity}"
end

def cli_cmd(config:, identity:)
  args = cli_config_args config: config, identity: identity
  "#{cli_base_cmd} #{args}"
end

def cli_base_cmd
  "bitmark-cli"
end

def cli_bitmarkd_status_cmd(config:, identity:)
  "#{cli_cmd config: config, identity: identity} bitmarkInfo 2>&1"
end

def cli_setup_command
  "#{cli_default_conf_cmd} setup #{cli_setup_args}"
end

def cli_get_users
  resp = JSON.parse(`#{cli_default_conf_cmd} info`)
  resp["identities"].map { |i| i["name"] }
end

def do_issue(again: false)
  @cli_result = nil
  # generate new issue or use previous one
  if again && !@prev_cli_cmd.nil?
    # clear previous existing result
    cmd = @prev_cli_cmd
  else
    cmd = cli_create_issue
    @prev_cli_cmd = cmd
  end

  puts "issue command: #{cmd}"
  @cli_result = `#{cmd}`
  puts "cli issue with response: #{@cli_result}"
  raise "Issue failed with message #{@cli_result}" if !@cli_result
end

def cli_create_issue
  "#{cli_default_conf_cmd} create #{cli_create_issue_args} 2>&1"
end

def cli_get_tx_status(id)
  `#{cli_default_conf_cmd} status #{tx_id_args id}`
end

def cli_get_provenance(id)
  `#{cli_default_conf_cmd} provenance #{tx_id_args id}`
end
