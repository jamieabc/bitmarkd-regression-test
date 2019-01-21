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
Given(/^I have asset "(.*)" with "(\d+)" shares$/) do |name, amount|
end

When(/^I grant my friend "(.*)" with "(\d+)" shares$/) do |friend, amount|
end

Then(/^"(.*)" has "(\d+)" shares of "(.*)"/) do |friend, amount, name|
end

Then(/^I have "(\d+)" shares of "(.*)"$/) do |amount, name|
end

# Swap shares
# Given I have "100" shares of asset "The School of Athens"
# Given"Foo" has "200" shares of asset "Girl with a Pearl Earring"
# When I exchange "60" shares of mine for "30" shares of "Foo"
# Then I have "40" shares of "The school of Athens" and "30" shares of "Girl tiwh a pearl Earring"
# Then "Foo" has "60" shares of "The school Athens" and "170" shares of "Girl with a Pearl Earring"
