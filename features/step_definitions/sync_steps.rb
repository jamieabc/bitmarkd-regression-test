Given(/^some bitmarkds already working normally$/) do
  @bm3.start
end

Given(/^clean start one bitmarkd$/) do
  @bm4.stop
  @bm4.clean_bitmarkd_data
  @bm4.start
end

When(/^newly started bitmarkd works in "(.*)" mode$/) do |mode|
  @bm4.start
  @bm4.wait_status(mode)
end

Then(/^newly started bitmarkd should have same data as others$/) do
  same = @bm4.same_blockchain?(@bm5)
  expect(same).to be_truthy
end

Given(/^specific bitmarkd has longer chain than rest of others$/) do
  # bitmarkd3 is longer than others
  %w(@bm1, @bm2, @bm4).each do |bm|
    bm.stop
    bm.truncate_chain_to_block(1)
  end
end

Given(/^other bitmarkd connects to specific bitmarkd and works in "normal" mode$/) do
  [@bm1, @bm2, @bm4].each do |bm|
    bm.start
  end
end

Given(/^other bitmarkd with same chain data as specific bitmarkd$/) do
  same = @bm4.same_blockchain?(@bm3)
  @bm3.start
  @bm4.start
  expect(same).to be_truthy
end

Given(/^specific bitmarkd with same chain length but different data than others$/) do
  @bm4.stop
  @bm4.change_data_to_backup
  @bm4.truncate_chain_to_block(@bm3.block_height)
end

When(/^specific bitmarkd works in "normal" mode$/) do
  # bitmarkd takes some time to start
  puts "wait at most #{Bitmarkd.start_time} seconds for #{@bm4.name} to start"
  @bm4.start
  expect(@bm4.normal?).to be_truthy
end

Then(/^specific bitmarkd with same data as others$/) do
  same = @bm4.same_blockchain?(@bm5)
  expect(same).to be_truthy
end

After("@sync_last_scenario") do
  @bm3.start
  @bm4.start
  @bm5.start
end
