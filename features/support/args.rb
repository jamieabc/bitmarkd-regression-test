def cli_setup_args
  "-n #{@cli_network} -x #{cli_url} -d #{@cli_description}"
end

def cli_create_issue_args
  "#{asset_args} #{meta_args} -f #{fingerprint}"
end

def asset_args
  return "-a '#{@asset_name}'" if @asset_name
end

def fingerprint
  @fingerprint = Time.now.getutc.to_s
  "'#{@fingerprint}'"
end

def meta_args
  args = ""
  @asset_meta.each do |key, value|
    str = meta_str(key, value)
    args << "-m '#{str}' "
  end if @asset_meta && !@asset_meta.empty?
  args.strip
end

def meta_str(key, value)
  key + meta_separator + value
end

def meta_separator
  "\\u0000"
end

def tx_id_args(id)
  "-t #{id}"
end

def counter_sign_tx_args(id:, receiver:)
  "#{tx_id_args id} -r #{receiver}"
end

def unratified_tx_args(id:, receiver:)
  "-u #{tx_id_args id} -r #{receiver}"
end
