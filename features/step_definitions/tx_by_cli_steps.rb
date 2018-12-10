gem "openssl"
require "openssl"
require "socket"
require "rspec"
require "pry"

Given(/^I have asset name "(.*)" on blockchain$/) do |name|
  @asset_name = name
  @asset_quantity = 1
  @asset_meta = {}
  @asset_meta["owner"] = @me

  step "I issue first time and wait for it become valid"
end

When(/^I unratified transfer asset to my friend "(.*)"$/) do |friend|
  do_unratified_tx_to friend
end

When(/^pay for transfer fee$/) do
  puts "cli result: #{@cli_result}"
  json = JSON.parse(@cli_result)
  @pay_tx_id = json["transferId"]
  puts "bitmark payment tx id: #{@pay_tx_id}"
  btc_pay_cmd = wallet_password
  btc_pay_cmd.concat(" ", json["commands"]["BTC"])
  btc_pay_cmd.gsub!("${XDG_CONFIG_HOME}/bitmark-wallet/bitmark-wallet.conf", @wallet_file)

  # pay
  pay_result = `#{btc_pay_cmd} 2>&1`
  puts "btc payment tx id: #{JSON.parse(pay_result)["txId"]}"
end

When(/^wait transfer become valid$/) do
  wait_until_tx_status id: @pay_tx_id, exp_status: "confirmed"
end

When(/^I counter-sign transfer of asset to "(.*)"$/) do |friend|
end

Then(/^asset first owner is "(.*)"$/) do |owner|
  get_provenance_history
  first_owner_idx = 1
  first_owner = get_identity provenance: @provenance, idx: first_owner_idx
  expect(first_owner).to eq(get_owner(owner))
end

Then(/^asset latest owner is "(.*)"$/) do |owner|
  get_provenance_history
  latest_owner_idx = 0
  latest_owner = get_identity provenance: @provenance, idx: latest_owner_idx
  expect(latest_owner).to eq(get_owner(owner))
end

def do_unratified_tx_to(receiver)
  tx_args = unratified_tx_args(id: @tx_id, receiver: receiver)
  puts "\nunratified tx cmd: #{cli_default_user_cmd} transfer #{tx_args}\n"
  @cli_result = `#{cli_default_user_cmd} transfer #{tx_args} 2>&1`
end

def get_owner(owner)
  return @cli_identity if owner == "me"
  owner
end
