Given(/^I have bitmark-cli config file$/) do
  @bm1 = Bitmarkd.new(bm_num: 1)
  @bm2 = Bitmarkd.new(bm_num: 2)
  @bm3 = Bitmarkd.new(bm_num: 3)
  @bm4 = Bitmarkd.new(bm_num: 4)
  @bm5 = Bitmarkd.new(bm_num: 5)
  @wallet = Wallet.new
  @btc = BTC.new(Wallet.btc_addr)
end

Given(/^I have a friend "(.*)" with bitmark account$/) do |friend|
  check_identity(friend)
end

Given(/^some bitmarkds already working normally$/) do
  Bitmarkd.start_all(@bm3, @bm4, @bm5)
end

Given(/^wallet has enough balance to pay$/) do
  raise "Error: wallet config file #{@wallet.conf} not exist" unless @wallet.exist?

  unless @wallet.btc_enough?
    BTC.send_tokens
  end

  expect(@wallet.btc_balance).to be >= @wallet.min_btc_balance
end

def check_identity(id)
  identities = @bm3.identities
  raise "#{@bm3.name} doesn't have identity #{id}" unless identities.include?(id)
end
