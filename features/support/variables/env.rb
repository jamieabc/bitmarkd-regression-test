# frozen_string_literal: true

# environment variables
module Variables
  module Env
    def home
      ENV["HOME"]
    end

    def go_path
      ENV["GOPATH"]
    end

    def go_bin_path
      "#{go_path}/bin"
    end
  end
end
