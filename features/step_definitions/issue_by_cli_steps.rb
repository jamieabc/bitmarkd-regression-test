gem 'openssl'
require 'openssl'
require 'socket'
require 'rspec'
require 'pry'

Given(/^I have a digital asset named "(.*)"$/) do |name|
  @asset_name = name
end

Given(/^I have a digital asset$/) do
  @asset_name = ""
end

Given(/^I have only "(\d+)" amount$/) do |amount|
  @aset_quantity = amount
end

Given(/^I want metadata of "(.*)" to be "(.*)"$/) do |key, value|
  # create a hash if not exist
  if @asset_meta.nil?
    @asset_meta = {}
  end

  @asset_meta[key] = value
end

When(/^I issue$/) do
  cmd = cli_create_issue_command
  @result = `#{cmd}`
  puts "issue with response: #{@result}"
  raise "Issue faile with message #{@result}" if !@result
end

Then(/^I can have a "(.*)" record on blockchain$/) do |expected|
  @issue_id = get_issue_id_from_response
  puts "wait issue to be confirmed..."
  status = cli_get_issue_status(expected)
  raise "issue #{@issue_id} status not #{expected}" if status.downcase != expected.downcase

  get_issue_data
end

Then(/^asset name is "(.*)"$/) do |expected_name|
  expect(@issued["result"]["assets"].first["data"]["name"]).to eq(expected_name)
end

Then(/^asset metadata of "(.*)" is "(.*)"$/) do |expected_key, expected_value|
  expected = returned_meta_str(expected_key, expected_value)
  got = @issued["result"]["assets"].first["data"]["metadata"]
  expect(got).to eql(expected)
end

Then(/^asset quantity is "(\d+)"$/) do |expected_quantity|
  get_prvenance_data
  puts "provenance: #{@provenance}"
end

Then(/^I got an error message of "(.*)"$/) do |msg|
  expect(@result).to include(msg)
end

def open_ssl_socket
  socket = TCPSocket.new('172.16.23.113', 2230)
  ssl = OpenSSL::SSL::SSLSocket.new(socket)
  ssl.sync_close = true
  ssl.connect
  ssl
end

def get_issue_data
  ssl = open_ssl_socket
  ssl.puts "{\"id\":\"1\",\"method\":\"Assets.Get\",\"params\":[{\"fingerprints\": [\"#{@fingerprint}\"]}]}"
  @issued = JSON.parse(ssl.gets)
end

def get_prvenance_data
  ssl = open_ssl_socket
  ssl.puts "{\"id\":\"1\",\"method\":\"Bitmark.Provenance\",\"params\":[{\"txId\": [\"#{@issue_id}\"]}]}"
  @provenance = JSON.parse(ssl.gets)
end

def get_issue_id_from_response
  json = JSON.parse(@result)
  json["issueIds"].first
end

def cli_get_issue_status(expected)
  status = "pending"
  retry_cnt = 40
  while retry_cnt > 0
    result = cli_query_issue
    json = JSON.parse(result)
    if json && json["status"]
      status = json["status"]
      break if status.downcase == expected.downcase
    end
    retry_cnt -= 1
    sleep 5
  end
  status
end

def cli_query_issue
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
