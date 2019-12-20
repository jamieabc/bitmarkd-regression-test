# frozen_string_literal: true

module Variables
  # timing variables
  class Timing
    def self.start_interval
      300
    end

    def self.check_interval
      10
    end

    def self.tx_limit
      60 * 10
    end

    def self.tx_check_times
      tx_limit / check_interval
    end
  end
end