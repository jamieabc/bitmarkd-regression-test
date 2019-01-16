require "faker"

module Cli
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module InstanceMethods
    def init_cli
      @cli_conf = "cli#{bm_num}.conf"
      @password = "12345678"
      @default_identity = "regression test user"
      reset_cli
    end

    def reset_cli
      reset_var_list.each { |var| var = nil }
    end

    def reset_var_list
      [@response, @issued, @fingerprint, @prev_cmd, @tx_id, @pay_tx_id,
       @asset_name, @asset_quantity, @asset_meta, @provenance]
    end

    def cli
      "bitmark-cli"
    end

    def cli_base_cmd(identity = default_identity)
      "#{cli} -c #{cli_conf} -i '#{identity}' -p #{password}"
    end

    def bm_status_cmd(identity)
      "#{cli_base_cmd(identity)} bitmarkInfo 2>&1"
    end

    def identities
      resp = JSON.parse(`#{cli_base_cmd} info`)
      resp["identities"].map { |i| i["name"] }
    end

    def issue(again: false)
      self.response = nil

      # generate new issue or use previous one
      if again && !prev_cmd.nil?
        # clear previous existing result
        cmd = prev_cmd
      else
        cmd = issue_cmd
        self.prev_cmd = cmd
      end

      puts "issue command: #{cmd}"
      self.response = `#{cmd}`
      puts "cli issue with response: #{response}"
      raise "Issue failed with message #{response}" unless response
    end

    def issue_cmd
      "#{cli_base_cmd} create #{issue_args} 2>&1"
    end

    def issue_args
      "#{asset_args} #{meta_args} -f \"#{gen_fingerprint}\""
    end

    def asset_args
      return "-a \"#{asset_name}\"" if asset_name
    end

    def gen_fingerprint
      word = Faker::Lorem.word
      time = Time.now.getutc.to_s
      @fingerprint = "#{time} #{word}"
    end

    def meta_args
      args = ""
      if asset_meta && !asset_meta.empty?
        asset_meta.each do |key, value|
          str = meta_str(key, value)
          args << "-m '#{str}' "
        end
      end
      args.strip
    end

    def meta_str(key, value)
      key + meta_separator + value
    end

    def meta_separator
      "\\u0000"
    end

    def tx_status(id)
      `#{cli_base_cmd} status #{self.class.tx_id_args(id)}`
    end

    def query_provenance(id)
      `#{cli_base_cmd} provenance #{self.class.tx_id_args(id)}`
    end

    def url
      "#{ip}:#{port}"
    end
  end

  module ClassMethods
    def tx_limit_time
      60 * 10
    end

    def tx_id_args(id)
      "-t #{id}"
    end

    def counter_sign_tx_args(id:, receiver:)
      "#{self.tx_id_args(id)} -r #{receiver}"
    end

    def unratified_tx_args(**hsh)
      # "-u #{self.class.tx_id_args(id)} -r #{receiver}"
      "-u #{self.counter_sign_tx_args(hsh)}"
    end
  end
end
