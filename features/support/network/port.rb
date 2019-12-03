# frozen_string_literal: true

module Network
  # port
  class Port
    attr_reader :node_index, :default_rpc, :default_node

    def initialize(index)
      @node_index = index
      @default_rpc = "2#{node_index}31"
      @default_node = "2#{node_index}30"
    end

    def ci_port_prefix
      "2"
    end

    def rpc
      run_ci? ? "#{ci_port_prefix}#{default_rpc}" : default_rpc
    end

    def node
      run_ci? ? "#{ci_port_prefix}#{default_node}" : default_node
    end
  end
end