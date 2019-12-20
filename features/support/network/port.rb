# frozen_string_literal: true

module Network
  # port
  class Port
    attr_reader :node_index, :default_rpc, :default_node

    def initialize(index)
      @node_index = index
      @default_rpc = "22#{node_index}31"
      @default_node = "22#{node_index}30"
    end

    def rpc
      default_rpc
    end

    def node
      default_node
    end
  end
end