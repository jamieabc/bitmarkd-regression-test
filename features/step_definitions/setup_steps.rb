Given(/^I have bitmark-cli config file$/) do
  @bm1 = Bitmarkd.new(bm_num: 1, port: 2130)
  @bm2 = Bitmarkd.new(bm_num: 2, port: 2230)
  @bm3 = Bitmarkd.new(bm_num: 3, port: 2330)
  @bm4 = Bitmarkd.new(bm_num: 4, port: 2430)
  @bm5 = Bitmarkd.new(bm_num: 5, port: 2530)
  @wallet = Wallet.new
  @btc = BTC.new(Wallet.btc_addr)
end

Given(/^I have a friend "(.*)" with bitmark account$/) do |friend|
  # create user if not exist
  unless user_exist? friend
    create_new_user friend
  end
end

Given(/^wallet has enough balance to pay$/) do
  raise "Error: wallet config file #{@wallet.file} not exist" unless @wallet.exist?
  @wallet.prepare_tokens(@btc)
  btc_balance = @wallet.btc_balance

  expect(btc_balance).to be >= @wallet.min_btc_balance
end

def user_exist?(name)
  users = @bm3.identities
  users.include? name
end
