Given(/^I have asset name "(.*)" on blockchain$/) do |name|
  @bm3.asset_name = name
  @bm3.asset_quantity = 1
  @bm3.asset_meta = {}
  @bm3.asset_meta["owner"] = @bm3.default_identity

  step "I issue first time and wait for it become valid"
end

When(/^I unratified transfer asset to my friend "(.*)"$/) do |friend|
  do_unratified_tx_to(friend)
end

When(/^pay for transfer fee$/) do
  puts "cli result: #{@bm3.response}"
  json = JSON.parse(@bm3.response)
  @bm3.pay_tx_id = json["transferId"]
  puts "bitmark payment tx id: #{@bm3.pay_tx_id}"
  btc_pay_cmd = @wallet.cmd_prefix
  btc_pay_cmd.concat(" ", json["commands"]["BTC"])
  btc_pay_cmd.gsub!("${XDG_CONFIG_HOME}/bitmark-wallet/bitmark-wallet.conf", @wallet.conf)

  # pay
  pay_result = `#{btc_pay_cmd} 2>&1`
  puts "btc payment tx id: #{JSON.parse(pay_result)["txId"]}"
end

When(/^wait transfer become valid$/) do
  BTC.mine
  @bm3.wait_tx_status(id: @bm3.pay_tx_id, exp_status: "confirmed")
end

When(/^I counter-sign transfer asset to my friend "(.*)"$/) do |friend|
  do_counter_sign_tx_to(friend)
end

When(/^"(.*)" also counter-signs transfer$/) do |user|
  do_counter_sign_receive(user)
end

# And "Foo" also counter-signs transfer
# And pay for transfer fee
# And wait transfer become valid
# Then asset first owner is "me"
# And asset latest owner is "Foo"

Then(/^asset first owner is "(.*)"$/) do |owner|
  @bm3.provenance_history
  first_owner_idx = 1
  first_owner = @bm3.provenance_owner(idx: first_owner_idx)
  expect(first_owner).to eq(get_owner(owner))
end

Then(/^asset latest owner is "(.*)"$/) do |owner|
  @bm3.provenance_history
  latest_owner_idx = 0
  latest_owner = @bm3.provenance_owner(idx: latest_owner_idx)
  expect(latest_owner).to eq(get_owner(owner))
end

def do_unratified_tx_to(receiver)
  do_transfer(receiver: receiver, counter_sign: false)
end

def do_counter_sign_tx_to(receiver)
  do_transfer(receiver: receiver, counter_sign: true)
end

def do_counter_sign_receive(receiver)
  json = JSON.parse(@bm3.response)
  tx = json["transfer"]
  cmd = @bm3.base_cmd(receiver)
  @bm3.response = `#{cmd} countersign -t #{tx} 2>&1`
end

def do_transfer(receiver:, counter_sign:)
  arg = tx_args(receiver: receiver, counter_sign: counter_sign)
  cmd = @bm3.base_cmd
  puts "\ntx cmd: #{cmd} transfer #{arg}\n"
  @bm3.response = `#{cmd} transfer #{arg} 2>&1`
end

def tx_args(receiver:, counter_sign:)
  if counter_sign == true
    Bitmarkd.counter_sign_tx_args(id: @bm3.tx_id, receiver: receiver)
  else
    Bitmarkd.unratified_tx_args(id: @bm3.tx_id, receiver: receiver)
  end
end

def get_owner(owner)
  return @bm3.default_identity if owner == "me"
  owner
end
