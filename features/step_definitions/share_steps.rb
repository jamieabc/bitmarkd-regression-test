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
  meta = {}
  meta["owner"] = @bm3.default_identity
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

Then(/^"(.*)" has "(\d+)" shares of asset/) do |friend, amount|
  id, balance = @bm3.balance(@bm3.share_id, friend)
  expect(balance).to eq(amount)
end

Then(/^I have "(\d+)" shares of asset$/) do |amount|
  id, balance = @bm3.balance
  expect(balance).to eq(amount)
end

Then(/^I am not allowed to grant "(\d+)" shares of asset to "(.*)"$/) do |amount, friend|
  @bm3.grant(receiver: friend, quantity: amount)
  resp = @bm3.counter_sign_grant(friend)
  expect(resp).to include("insufficient shares")
end

# Swap shares

# Given"Foo" has "200" shares of asset "Girl with a Pearl Earring"
# When I exchange "60" shares of mine for "30" shares of "Foo"
# Then I have "40" shares of "The school of Athens" and "30" shares of "Girl tiwh a pearl Earring"
# Then "Foo" has "60" shares of "The school Athens" and "170" shares of "Girl with a Pearl Earring"
