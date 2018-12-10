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

When(/^I counter-sign transfer asset to my friend "(.*)"$/) do |friend|
  do_counter_sign_tx_to friend
end

When(/^"(.*)" also counter-signs transfer$/) do |user|
  do_counter_sign_receive user
end

# And "Foo" also counter-signs transfer
# And pay for transfer fee
# And wait transfer become valid
# Then asset first owner is "me"
# And asset latest owner is "Foo"

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
  do_transfer(receiver: receiver, counter_sign: false)
end

def do_counter_sign_tx_to(receiver)
  do_transfer(receiver: receiver, counter_sign: true)
end

def do_counter_sign_receive(receiver)
  json = JSON.parse(@cli_result)
  tx_hex = json["transfer"]
  cli_base_cmd = cli_user_cmd user: receiver, password: @cli_password
  @cli_result = `#{cli_base_cmd} countersign --transfer #{tx_hex}`
end

def do_transfer(receiver:, counter_sign:)
  arg = tx_args(receiver: receiver, counter_sign: counter_sign)
  puts "\ntx cmd: #{cli_default_user_cmd} transfer #{arg}\n"
  @cli_result = `#{cli_default_user_cmd} transfer #{arg} 2>&1`
end

def tx_args(receiver:, counter_sign:)
  counter_sign ? (counter_sign_tx_args id: @tx_id, receiver: receiver) :
    (unratified_tx_args id: @tx_id, receiver: receive)
end

def get_owner(owner)
  return @cli_identity if owner == "me"
  owner
end
