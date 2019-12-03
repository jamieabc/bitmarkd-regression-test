# frozen_string_literal: true

module Network
  # ip
  class IP

    def ip
      run_ci? ? server : local
    end

    private

    def local
      '127.0.0.1'
    end

    def server
      '172.24.150.110'
    end
  end
end