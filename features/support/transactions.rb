require 'pry'

def wait_until_tx_status(id:, exp_status:)
  puts "wait tx #{id} to become #{exp_status}..."
  status = check_tx_status(id: id, exp_status: exp_status)

  raise "issue #{id} status not #{exp_status}" if status.downcase != exp_status

  rpc_query_issued_data
end

def check_tx_status(id:, exp_status:)
  # for i in 0..query_retry_count
  start = Time.now
  resp_status = nil
  loop do
    result = cli_get_tx_status(id)
    puts "cli result: #{result}"
    json = JSON.parse(result)
    puts "cli result json: #{json}"
    if json && json["status"]
      resp_status = json["status"]
      break if resp_status.casecmp? exp_status
    end

    sleep 10
  end
  finish = Time.now
  puts "wait tx id #{id} become #{exp_status} takes #{finish - start} seconds"

  resp_status
end

def open_ssl_socket
  socket = TCPSocket.new("172.16.23.113", 2230)
  ssl = OpenSSL::SSL::SSLSocket.new(socket)
  ssl.sync_close = true
  ssl.connect
  ssl
end

def rpc_query_issued_data
  ssl = open_ssl_socket
  ssl.puts "{\"id\":\"1\",\"method\":\"Assets.Get\",\"params\":[{\"fingerprints\": [\"#{@fingerprint}\"]}]}"
  @issued = JSON.parse(ssl.gets)
end

def get_identity(provenance:, idx:)
  # make sure provenance is long enough
  if provenance.length <= idx
    puts "provenance: #{provenance}, target element index: #{idx}"
    raise "Error, provenance is not long enough"
  end
  provenance[idx]['_IDENTITY']
end

def get_provenance_history
  if @provenance.nil? || @provenance.empty?
    resp = cli_get_provenance @pay_tx_id
    @provenance = JSON.parse(resp)["data"]
  end
end
