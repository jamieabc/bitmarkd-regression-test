require "pry"

def wait_until_issue_tx_status(id:, exp_status:)
  # mine some blocks, make sure transfer is confirmed
  mine_block(6)
  puts "wait tx #{id} become #{exp_status}..."
  status = check_tx_status(id: id, exp_status: exp_status)

  raise "issue #{id} status not #{exp_status}" if !(status.casecmp? exp_status)

  rpc_query_issued_data
end

def check_tx_status(id:, exp_status:)
  # for i in 0..query_retry_count
  start = Time.now
  resp_status = nil
  iterate_count = 0
  tx_limit_exceed = false
  loop do
    result = cli_get_tx_status(id)
    json = JSON.parse(result)
    iterate_count += 1
    if json && json["status"]
      resp_status = json["status"]
      tx_limit_exceed = tx_limit_exceed? iterate_count
      break if (resp_status.casecmp? exp_status) || tx_limit_exceed
    end

    sleep sleep_unit_sec
  end
  finish = Time.now
  if tx_limit_exceed
    puts "time limit exceed"
  else
    puts "takes #{finish - start} seconds"
  end

  resp_status
end

def tx_limit_exceed?(iteration)
  iteration * sleep_unit_sec >= wait_tx_limit_sec
end

def get_identity(provenance:, idx:)
  # make sure provenance is long enough
  if provenance.length <= idx
    puts "provenance: #{provenance}, target element index: #{idx}"
    raise "Error, provenance is not long enough"
  end
  provenance[idx]["_IDENTITY"]
end

def get_provenance_history
  if @provenance.nil? || @provenance.empty?
    resp = cli_get_provenance @pay_tx_id
    @provenance = JSON.parse(resp)["data"]
  end
end
