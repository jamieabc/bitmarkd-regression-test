Given(/^I have digital asset name "(.*)"$/) do |name|
  @asset_name = name
end

Given(/^amount "(.*)", metadata "(.*)" to be "(.*)"$/) do |amount, key, value|
  @asset_quantity = amount.length.zero? ? 0 : amount.to_i

  # initialized metadata hash
  if @asset_meta.nil?
    @asset_meta = {}
  end

  @asset_meta[key] = value
end

When(/^I issue$/) do
  do_new_issue
end

When(/^I issue first time and wait for it become valid$/) do
  do_new_issue
  set_tx_id_from_response
  wait_until_issue_tx_status id: @tx_id, exp_status: "confirmed"
end

When(/^I issue same asset second time$/) do
  do_prev_issue
end

Then(/^I have valid asset stored on blockchain$/) do
  set_tx_id_from_response
  wait_until_issue_tx_status id: @tx_id, exp_status: "confirmed"
end

Then(/^with name "(.*)", amount "(.*)", metadata "(.*)" to be "(.*)"$/) do |exp_name, exp_amount, exp_key, exp_value|
  result = @issued["result"]
  asset = result ? result["assets"].first : nil
  data = asset ? asset["data"] : nil

  if data.nil?
    puts "issued result: #{@issued}"
    raise "Error issue record."
  end

  expect(data["name"]).to eq(exp_name)

  exp_meta_str = returned_meta_str(exp_key, exp_value)

  got = @issued["result"]["assets"].first["data"]["metadata"]
  expect(got).to eql(exp_meta_str)

  issued_amount = JSON.parse(@cli_result)["issueIds"].size if @cli_result
  target_amount = exp_amount.length.zero? ? 0 : exp_amount.to_i
  expect(issued_amount).to eq(target_amount)
end

Then(/^I failed with cli error message "(.*)"$/) do |err_msg|
  expect(@cli_result).to include(err_msg)
end

Then(/^I need to pay for second issue$/) do
  json = JSON.parse(@cli_result)
  expect(json.has_key? "payments").to be_truthy
  expect(json.has_key? "commands").to be_truthy
end

def do_new_issue
  do_issue(again: false)
end

def do_prev_issue
  do_issue(again: true)
end

def set_tx_id_from_response
  raise "Issue failed with message #{@cli_result}" if !@cli_result
  json = JSON.parse(@cli_result)
  @tx_id = json["issueIds"].first
end

def returned_meta_str(key, value)
  key + "\u0000" + value
end
