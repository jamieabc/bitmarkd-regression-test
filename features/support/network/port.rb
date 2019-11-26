# frozen_string_literal: true

module Network
  # port
  class Port
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def rpc
      "2#{index}31"
    end

    def node
      "2#{index}30"
    end
  end
end