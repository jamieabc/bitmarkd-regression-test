# frozen_string_literal: true

module Network
  # ip
  class IP
    attr_reader :mac

    def initialize(os)
      @mac = os == 'Darwin'
    end

    def ip
      @mac ? local : server
    end

    private

    def local
      '127.0.0.1'
    end

    def server
      '172.16.23.113'
    end
  end
end