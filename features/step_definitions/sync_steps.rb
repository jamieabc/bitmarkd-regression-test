Given(/^clean start one bitmarkd$/) do
  @bm4.stop
  @bm4.clear_data
  @bm4.clear_reservoir_cache
  @bm4.start
end

When(/^newly started bitmarkd works in normal mode$/) do
  @bm4.start
end

Then(/^newly started bitmarkd should have same data as others$/) do
  same = @bm4.same_blockchain?(@bm5)
  expect(same).to be_truthy
end

Given(/^specific bitmarkd has longer chain than rest of others$/) do
  # bitmarkd3 is longer than others
  truncate_to_blk = @bm3.block_height / 2
  puts "#{@bm3.name} current block height #{@bm3.block_height}" \
       ", truncate others to #{truncate_to_blk}"

  [@bm1, @bm2, @bm4].each do |bm|
    bm.stop
    bm.truncate_to_block(truncate_to_blk)
    bm.clear_reservoir_cache
    bm.clear_peer_cache
  end
end

Given(/^other bitmarkd connects to specific bitmarkd and works in normal mode$/) do
  # although bitmarkd3 is not stopped, re-connected bitmarkd 1 and 2 might cause
  # it into resynchronise mode
  Bitmarkd.start_all(@bm1, @bm2, @bm3, @bm4)
end

Then(/^other bitmarkd with same chain data as specific bitmarkd$/) do
  same = @bm4.same_blockchain?(@bm3)
  expect(same).to be_truthy
end

Given(/^specific bitmarkd with same chain length but different data than others$/) do
  @bm4.stop
  @bm4.restore_backup
  @bm4.truncate_to_block(@bm3.block_height)
end

When(/^specific bitmarkd works in "normal" mode$/) do
  # bitmarkd takes some time to start
  puts "wait at most #{Variables::Timing.start_interval} seconds for #{@bm4.name} to start"
  @bm4.start
  expect(@bm4.normal?).to be_truthy
end

Then(/^specific bitmarkd with same data as others$/) do
  same = @bm4.same_blockchain?(@bm5)
  expect(same).to be_truthy
end
