# frozen_string_literal: true

module Variables
  # bitmarkd variables
  module Bitmarkd
    def data_dir
      "data"
    end

    def reservoir_cache_file
      'reservoir-local.cache'
    end

    def peer_cache_file
      'peers-local.json'
    end

    def bitmarkd_bin_path
      "#{go_bin_path}/bitmarkd"
    end

    def dumpdb_bin_path
      "#{go_bin_path}/bitmark-dumpdb"
    end

    def data_path
      "#{home}/.config/#{name}"
    end
  end
end