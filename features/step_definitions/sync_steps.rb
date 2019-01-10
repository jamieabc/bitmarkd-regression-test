require "pry"

Given(/^some bitmarkds already working normally$/) do
  # check normal status
  switch_cli_file_to_normal
  wait_until_bitmarkd_status("Normal")
end

Given(/^clean start one bitmarkd$/) do
  bm_num = 4
  stop_bitmarkd(bm_num)
  clean_bitmarkd_data(bm_num)
end

When(/^newly started bitmarkd works in "(.*)" mode$/) do |mode|
  bm_num = 4
  start_bitmarkd(bm_num)

  wait_until_bitmarkd_status(mode)
end

Then(/^newly started bitmarkd should have same data as others$/) do
  bm_num = 4
  same = same_blockchain?(5, bm_num)
  expect(same).to be_truthy
end

Given(/^specific bitmarkd with same chain length bug different data than others$/) do
  bm_num = 4
  stop_bitmarkd(bm_num)
  change_data_to_backup(bm_num)
  truncate_bitmarkd_to_consistent_chain_length(bm_num)
end

When(/^specific bitmarkd works in "(.*)" mode$/) do
  bm_num = 4
  start_bitmarkd(bm_num)

  # bitmarkd takes some time to start
  puts "wait #{bitmarkd_start_time_sec} seconds for bitmarkd #{bm_num} to start"
  sleep bitmarkd_start_time_sec

  wait_until_bitmarkd_status(mode)
end

Then(/^specific bitmarkd with same data as others$/) do
  bm_num = 4
  same = same_blockchain?(5, bm_num)
  expect(same).to be_truthy
end

Before("@sync_first_scenario") do
  # target backup one
  switch_cli_file_to_backup
end

# change cli file to use normal bitmarkd
After("@sync_last_scenario") do
  start_bitmarkd(4)
  start_bitmarkd(5)

  # wait for some time
  sleep bitmarkd_start_time_sec

  wait_until_bitmarkd_status("Normal")
  switch_cli_file_to_normal
end
