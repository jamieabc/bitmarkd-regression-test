gem "openssl"
require "openssl"
require "socket"

def open_ssl_socket
  socket = TCPSocket.new(host_ip, host_port)
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
