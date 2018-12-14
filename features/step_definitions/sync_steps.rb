require "pry"

Given(/^some bitmarkds already working normally$/) do
  # check normal status
  switch_cli_file_to_normal
  bm_status = get_bitmarkd_status
  expect(bm_status).to eq("Normal")

  # target backup one
  switch_cli_file_to_backup
end

Given(/^I clean start a bitmarkd$/) do
  stop_bitmarkd(4)
  clean_bitmarkd_data(4)
end

When(/^my newly started bitmarkd is working normally$/) do
  start_bitmarkd(4)

  # bitmarkd take some time to start
  puts "wait #{bitmarkd_start_time_sec}"
  sleep bitmarkd_start_time_sec

  wait_until_bitmarkd_status("Normal")
end

Then(/^my newly started bitmarkd should have same data as other nodes$/) do
  same = same_blockchain? 5, 4
  expect(same).to be_truthy
end

Given(/^my bitmarkd has forked blockchain history$/) do
  stop_bitmarkd(4)
  change_data_to_backup(4)
end

When(/^forked bitmarkd is working normally$/) do
  start_bitmarkd(4)

  # bitmarkd take some time to start
  puts "wait #{bitmarkd_start_time_sec}"
  sleep bitmarkd_start_time_sec

  wait_until_bitmarkd_status("Normal")
end

Then(/^forked bitmarkd will have same records as other notes$/) do
  same = same_blockchain? 5, 4
  expect(same).to be_truthy
end

# change cli file to use normal bitmarkd
After("@sync_last_scenario") do
  start_bitmarkd(4)
  start_bitmarkd(5)
  wait_until_bitmarkd_status("Normal")
  switch_cli_file_to_normal
end
