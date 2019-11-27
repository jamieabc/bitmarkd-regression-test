# frozen_string_literal: true

module Network
  # use rpc to get info
  class RPC
    attr_reader :ip, :port

    def initialize(ip:, port:)
      @ip = ip
      @port = port
    end

    def create_https
      http = Net::HTTP.new(ip, port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http
    end

    def status
      http = create_https
      begin
        resp = http.get(Variables::Uri.status)
      rescue IOError
        return ''
      end

      resp
    end

    def asset_info(data)
      http = create_https
      http.post(Variables::Uri.rpc, data, "Content-Type" => "application/json")
    end
  end
end