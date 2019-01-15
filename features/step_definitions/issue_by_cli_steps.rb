Given(/^I have digital asset name "(.*)"$/) do |name|
  @bm3.asset_name = name
end

Given(/^amount "(.*)", metadata "(.*)" to be "(.*)"$/) do |amount, key, value|
  @bm3.asset_quantity = amount.length.zero? ? 0 : amount.to_i

  # initialized metadata hash
  if @bm3.asset_meta.nil?
    @bm3.asset_meta = {}
  end

  @bm3.asset_meta[key] = value
end

When(/^I issue$/) do
  do_new_issue
end

When(/^I issue first time and wait for it become valid$/) do
  do_new_issue
  set_tx_id_from_response
  BTC.mine
  @bm3.wait_tx_status id: @bm3.tx_id, exp_status: "confirmed"
end

When(/^I issue same asset second time$/) do
  do_prev_issue
end

Then(/^I have valid asset stored on blockchain$/) do
  set_tx_id_from_response
  BTC.mine
  @bm3.wait_tx_status id: @bm3.tx_id, exp_status: "confirmed"
end

Then(/^with name "(.*)", amount "(.*)", metadata "(.*)" to be "(.*)"$/) do |exp_name, exp_amount, exp_key, exp_value|
  result = @bm3.issued["result"]
  asset = result ? result["assets"].first : nil
  data = asset ? asset["data"] : nil

  if data.nil?
    puts "issued result: #{@bm3.issued}"
    raise "Error issue record."
  end

  expect(data["name"]).to eq(exp_name)

  exp_meta_str = returned_meta_str(exp_key, exp_value)

  got = @bm3.issued["result"]["assets"].first["data"]["metadata"]
  expect(got).to eql(exp_meta_str)

  issued_amount = JSON.parse(@bm3.response)["issueIds"].size if @bm3.response
  target_amount = exp_amount.length.zero? ? 0 : exp_amount.to_i
  expect(issued_amount).to eq(target_amount)
end

Then(/^I failed with cli error message "(.*)"$/) do |err_msg|
  expect(@bm3.response).to include(err_msg)
end

Then(/^I need to pay for second issue$/) do
  json = JSON.parse(@bm3.response)
  expect(json.has_key? "payments").to be_truthy
  expect(json.has_key? "commands").to be_truthy
end

def do_new_issue
  @bm3.issue(again: false)
end

def do_prev_issue
  @bm3.issue(again: true)
end

def set_tx_id_from_response
  # raise error is empty or error message
  if @bm3.response.empty? || @bm3.response.include?("error")
    raise "Issue failed with message #{@bm3.response}"
  end

  json = JSON.parse(@bm3.response)
  @bm3.tx_id = json["issueIds"].first
end

def returned_meta_str(key, value)
  key + "\u0000" + value
end
