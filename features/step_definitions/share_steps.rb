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
