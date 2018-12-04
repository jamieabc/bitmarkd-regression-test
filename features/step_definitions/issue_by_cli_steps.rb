gem 'openssl'
require 'openssl'
require 'socket'
require 'rspec'
require 'pry'

Given(/^I have digital asset name "(.*)"$/) do |name|
  @asset_name = name
end

Given(/^amount "(.*)", metadata "(.*)" to be "(.*)"$/) do |amount, key, value| 
  @asset_quantity = amount.length.zero? ? 0 : amount.to_i

  # initialized metadata hash
  if @asset_meta.nil?
    @asset_meta = {}
  end 

  @asset_meta[key] = value
end

When(/^I issue$/) do
  cmd = cli_create_issue_command
  puts "issue command: #{cmd}"
  @result = `#{cmd}`
  puts "issue with response: #{@result}"
  raise "Issue faile with message #{@result}" if !@result
end

Then(/^I have valid asset stored on blockchain$/) do
  exp_status = 'confirmed'
  @issue_id = get_issue_id_from_response

  puts "wait issue to be confirmed..."
  status = check_issue_status(exp_status)

  raise "issue #{@issue_id} status not #{exp_status}" if status.downcase != exp_status

  rpc_query_issued_data
end

Then(/^with name "(.*)", amount "(.*)", metadata "(.*)" to be "(.*)"$/) do |exp_name, exp_amount, exp_key, exp_value|

  expect(@issued["result"]["assets"].first["data"]["name"]).to eq(exp_name)

  exp_meta_str = returned_meta_str(exp_key, exp_value)

  got = @issued["result"]["assets"].first["data"]["metadata"]
  expect(got).to eql(exp_meta_str)

  issued_amount = JSON.parse(@result)["issueIds"].size if @result
  target_amount = exp_amount.length.zero? ? 0 : exp_amount.to_i
  expect(issued_amount ).to eq(target_amount)
end

Then(/^I failed with cli error message "(.*)"$/) do |err_msg|
  expect(@result).to include(err_msg)
end

def open_ssl_socket
  socket = TCPSocket.new('172.16.23.113', 2230)
  ssl = OpenSSL::SSL::SSLSocket.new(socket)
  ssl.sync_close = true
  ssl.connect
  ssl
end

def rpc_query_issued_data
  ssl = open_ssl_socket
  ssl.puts "{\"id\":\"1\",\"method\":\"Assets.Get\",\"params\":[{\"fingerprints\": [\"#{@fingerprint}\"]}]}"
  @issued = JSON.parse(ssl.gets)
end

def get_issue_id_from_response
  json = JSON.parse(@result)
  json["issueIds"].first
end

def check_issue_status(expected_status)
  for i in 0..query_retry_count
    result = cli_get_issue_status
    json = JSON.parse(result)
    if json && json["status"]
      resp_status = json["status"]
      break if resp_status.downcase == expected_status.downcase
    end

    sleep 5
  end

  resp_status
end

def query_retry_count
  40
end

def cli_get_issue_status
  `#{cli_base_command} status #{cli_query_issue_args}`
end

def cli_query_issue_args
  "--txid #{@issue_id}"
end

def cli_create_issue_command
  "#{cli_base_command} create #{cli_create_issue_args} 2>&1"
end

def meta_separator
  "\\u0000"
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

def returned_meta_str(key, value)
  key + "\u0000" + value
end
