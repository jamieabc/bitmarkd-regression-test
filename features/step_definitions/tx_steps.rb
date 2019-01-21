Given(/^I have asset "(.*)" on blockchain$/) do |name|
  @bm3.asset_name = name
  @bm3.asset_quantity = 1
  @bm3.asset_meta = {}
  @bm3.asset_meta["owner"] = @bm3.default_identity

  step "I issue first time and wait for it become valid"
end

When(/^I unratified transfer asset to my friend "(.*)"$/) do |friend|
  @bm3.transfer(receiver: friend, counter_sign: false)
end

When(/^pay for transfer fee$/) do
  @bm3.pay(wallet: @wallet, crypto: "BTC")
end

When(/^wait transfer become valid$/) do
  BTC.mine
  @bm3.wait_tx_status(id: @bm3.pay_tx_id, exp_status: "confirmed")
end

When(/^I counter-sign transfer asset to my friend "(.*)"$/) do |friend|
  @bm3.transfer(receiver: friend, counter_sign: true)
end

When(/^"(.*)" also counter-signs transfer$/) do |user|
  @bm3.counter_sign(user)
end

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

def get_owner(owner)
  return @bm3.default_identity if owner == "me"
  owner
end
