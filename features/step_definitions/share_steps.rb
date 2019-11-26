# Create share
When(/^I split asset ownership into "(\d+)" shares$/) do |share_amount|
  @bm3.share_amount = share_amount
  @bm3.share
  @bm3.pay(wallet: @wallet, crypto: "BTC")
  BTC.mine
  @bm3.wait_tx_status(id: @bm3.tx_id, exp_status: "confirmed")
end

Then(/^asset become "(\d+)" shares$/) do |share_amount|
  id, balance = @bm3.balance
  expect(id).to eq(@bm3.share_id)
  expect(balance).to eq(share_amount)
end

# Grant shares
Given(/^I have "(\d+)" shares of asset "(.*)"$/) do |amount, asset|
  # refactor later, use method to setup asset info instead of accessing
  # instance variable. Also, maybe it's necessary to provide a method to auto-gen
  # asset related data
  meta = {
    "owner" => @bm3.default_identity,
  }
  @bm3.setup_issue_args(name: asset, meta: meta, quantity: amount)

  step "I issue first time and wait for it become valid"
  step "I split asset ownership into \"#{amount}\" shares"
end

When(/^I grant "(.*)" with "(\d+)" shares$/) do |friend, amount|
  @bm3.grant(receiver: friend, quantity: amount)
  @bm3.counter_sign_grant(friend)
  @bm3.pay(wallet: @wallet, crypto: "BTC")
  BTC.mine
  @bm3.wait_tx_status(id: @bm3.tx_id, exp_status: "confirmed")
end

Then(/^"(.*)" has "(\d+)" shares of asset$/) do |friend, amount|
  _, balance = @bm3.balance(@bm3.share_id, friend)
  expect(balance).to eq(amount)
end

Then(/^I have "(\d+)" shares of asset$/) do |amount|
  _, balance = @bm3.balance
  expect(balance).to eq(amount)
end

Then(/^I am not allowed to grant "(\d+)" shares of asset to "(.*)"$/) do |amount, friend|
  @bm3.grant(receiver: friend, quantity: amount)
  resp = @bm3.counter_sign_grant(friend)
  expect(resp).to include("insufficient shares")
end

# Swap shares
Given(/^I have "(\d+)" shares of asset "(.*)" - (.*)$/) do |amount, name, asset_alias|
  meta = {
    "owner" => @bm3.default_identity
  }
  @bm3.setup_issue_args(name: name, meta: meta, quantity: amount)
  instance_variable_set("@owner_#{asset_alias.downcase}".to_sym, @bm3.default_identity)

  @bm3.issue(again: false)
  @bm3.tx_id = @bm3.response["issueIds"].first
  BTC.mine
  @bm3.wait_tx_status(id: @bm3.tx_id, exp_status: "confirmed")

  @bm3.share_amount = amount
  @bm3.share
  @bm3.pay(wallet: @wallet, crypto: "BTC")
  BTC.mine
  @bm3.wait_tx_status(id: @bm3.tx_id, exp_status: "confirmed")
end

Given(/^"(.*)" has "(\d+)" shares of asset "(.*)" - (.*)$/) do |friend, amount, name, asset_alias|
  meta = {
    "owner" => friend,
  }
  @owner_b = friend
  instance_variable_set("@owner_#{asset_alias.downcase}".to_sym, friend)
  @bm4.setup_issue_args(name: name, meta: meta, quantity: amount, identity: @owner_b)
  @bm4.issue(again: false)
  @bm4.tx_id = @bm4.response["issueIds"].first
  BTC.mine
  @bm4.wait_tx_status(id: @bm4.tx_id, exp_status: "confirmed")

  @bm4.share_amount = amount
  @bm4.share
  @bm4.pay(wallet: @wallet, crypto: "BTC")
  BTC.mine
  @bm4.wait_tx_status(id: @bm3.tx_id, exp_status: "confirmed")
end

When(/^I exchange "(\d+)" shares of asset "(.*)" with "(.*)" for "(\d+)" shares of asset "(.*)"$/) do |first_amount, _, friend, second_amount, _|
  sleep Variables::Timing.check_interval # in case transaction is not broadcast
  @bm3.grant(receiver: friend, quantity: first_amount)
  @bm3.counter_sign_grant(friend)
  @bm3.pay(wallet: @wallet, crypto: "BTC")
  BTC.mine
  @bm3.wait_tx_status(id: @bm3.tx_id, exp_status: "confirmed")

  @bm4.grant(receiver: @bm4.default_identity, quantity: second_amount)
  @bm4.counter_sign_grant(@bm4.default_identity)
  @bm4.pay(wallet: @wallet, crypto: "BTC")
  BTC.mine
  @bm4.wait_tx_status(id: @bm4.tx_id, exp_status: "confirmed")
end

Then(/^I have "(\d+)" shares of asset "(.*)", "(\d+)" shares of asset "(.*)"$/) do |first_amount, _, second_amount, _|
  id, balance_a = @bm3.balance
  id, balance_b = @bm4.balance

  expect(balance_a).to eq(first_amount)
  expect(balance_b).to eq(second_amount)
end

Then(/^"(.*)" has "(\d+)" shares of asset "(.*)", "(\d+)" shares of asset "(.*)"$/) do |friend, first_amount, _, second_amount, _|
  id, balance_a = @bm3.balance(@bm3.share_id, "Foo")
  id, balance_b = @bm4.balance(@bm4.share_id, "Foo")

  expect(balance_a).to eq(first_amount)
  expect(balance_b).to eq(second_amount)
end
