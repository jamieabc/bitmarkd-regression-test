require "faker"

module Cli
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module InstanceMethods
    def init_cli
      @password = "12345678"
      @default_identity = "regression test user"
      @network = "local"
      reset_cli
    end

    def reset_cli
      reset_var_list.each { |var| var = nil }
      # initialize payment keys, it will be used to check if crypto payment is supported
      @payments = {BTC: "", LTC: ""}
    end

    def reset_var_list
      [@response, @issued, @fingerprint, @prev_cmd, @tx_id, @pay_tx_id,
       @asset_name, @asset_quantity, @asset_meta, @provenance, @share_amount,
       @share_id, @share_info]
    end

    def cli
      "bitmark-cli"
    end

    # TODO: use single parameter for identity decision
    def cli_base_cmd
      "#{cli} -n #{network} -i '#{identity}' -p #{password}"
    end

    def identities
      `#{cli_base_cmd} list`
    end

    def setup_issue_args(name:, meta:, quantity:, identity: default_identity)
      @asset_name = name
      @asset_quantity = quantity
      @asset_meta = meta
      @identity = identity
    end

    def infinite_issue
      i = 0
      while true
        name = "#{Faker::Name.name}-#{Faker::PhoneNumber.phone_number}"
        setup_issue_args(name: name, meta: {"owner" => "me"}, quantity: 1)
        puts "new issue"
        issue(again: false)
        if @response.empty?
          raise "issue failed with no response"
        end
        puts "response: #{@response}"

        @tx_id = @response["issueIds"].first
        puts "tx id: #{@tx_id}"
        BTC.mine if (i % 90).zero?
        sleep 1
        i += 1
      end
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

      puts "issue command:"
      ap cmd
      resp = `#{cmd}`
      # extract a method to parse response
      if resp.downcase.include?("error")
        puts "Issue failed with message #{resp}"
        self.response = resp
      else
        self.response = JSON.parse(resp)
        puts "cli issue with response: #{response}"
      end
    end

    def issue_cmd
      "#{cli_base_cmd} create #{issue_args} 2>&1"
    end

    def issue_args
      gen_fingerprint
      "#{asset_args} #{meta_args} -f \"#{fingerprint}\""
    end

    def asset_args
      return "-a \"#{asset_name}\"" if asset_name
    end

    def gen_fingerprint
      word = "#{Faker::Lorem.word}-#{Faker::PhoneNumber.phone_number}"
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
      `#{cli_base_cmd} status #{tx_id_args(id)}`
    end

    def query_provenance(id)
      `#{cli_base_cmd} provenance #{tx_id_args(id)}`
    end

    def url
      "#{ip}:#{port}"
    end

    def transfer(receiver:, counter_sign:)
      args = (counter_sign == true) ?
               counter_sign_tx_args(id: tx_id, receiver: receiver) :
               unratified_tx_args(id: tx_id, receiver: receiver)
      cmd = transfer_cmd(args)
      self.response = JSON.parse(`#{cmd}`)
      puts "transfer cli result:"
      ap response
      extract_transfer_response(counter_sign)
    end

    # balance response:
    # {
    #   "balances": [
    #     {
    #       "shareId": "...",
    #       "confirmed": 30,
    #       "spend": 0,
    #       "available": 30
    #     }
    #   ]
    # }
    def balance(share = share_id, identity = default_identity)
      # TODO: this function is ambiguous, it gueses the identity and id
      cmd = balance_cmd(share, identity)
      resp = JSON.parse(`#{cmd}`)
      puts "cli balance response: #{resp}"
      self.share_info = resp["balances"]
      item = share_info.first
      [item["shareId"], item["confirmed"]]
      # TODO: the sequence is ambiguous, need to be refactored
    end

    # balance will return all balances from that point, so limit count to 1
    def balance_cmd(share, id)
      @identity = id
      cmd = "#{cli_base_cmd} balance -s #{share} -c 1 -o '#{id}'"
      puts "balance command:"
      ap cmd
      cmd
    end

    def pay(wallet:, crypto:)
      c = crypto.upcase
      raise "#{crypto} not support" if payments.keys.include?(c)
      pay_info = response["payments"][c].first
      resp = wallet.pay(
        crypto,
        response["payId"],
        pay_info["address"],
        pay_info["amount"]
      )
      json = JSON.parse(resp)
      puts "pay result:"
      ap json
      crypto_tx_id = json["txId"]
      puts "#{crypto.upcase} payment transaction ID: #{crypto_tx_id}"
    end

    # two transfer types has different response
    # unratified transfer with bitmarkd ID, payment transaction ID, pay commands
    # counter-sign transfer transfer ID for other ppl to counter-sign
    def extract_transfer_response(counter_sign)
      if counter_sign == true
        self.tx_id = response["transfer"]
      else
        hsh = {
          "tx_id=" => "bitmarkId",
          "pay_tx_id=" => "transferId",
        }
        extract_values_from_response(hsh)
        parse_payments
        tx_info
      end
    end

    def extract_counter_sign_grant_response
      hsh = {
        "tx_id=" => "grantId",
        "pay_tx_id=" => "payId",
      }
      extract_values_from_response(hsh)
      parse_payments
      tx_info
    end

    # counter_sign and counter_sign_grant has much similar behavior, should
    # refactor it
    def counter_sign(receiver)
      cmd = counter_sign_cmd(receiver)
      puts "counter sign command:"
      ap cmd
      self.response = JSON.parse(`#{cmd}`)
      puts "counter sign cli result:"
      ap response
      extract_transfer_response(false)
    end

    def counter_sign_grant(receiver)
      @identity = receiver
      cmd = counter_sign_cmd(receiver)
      puts "counter sign grant command:"
      ap cmd
      resp = `#{cmd}`
      if resp.include?("error")
        puts "response with error: #{resp}"
        return resp
      end

      self.response = JSON.parse(resp)
      puts "counter sign grant cli result:"
      ap response
      extract_counter_sign_grant_response
    end

    def counter_sign_cmd(receiver)
      @identity = receiver
      "#{cli_base_cmd} countersign -t #{tx_id} 2>&1"
    end

    def transfer_cmd(args)
      cmd = "#{cli_base_cmd} transfer #{args} 2>&1"
      puts "transfer command:"
      ap cmd
      cmd
    end

    def tx_id_args(id)
      "-t #{id}"
    end

    def counter_sign_tx_args(id:, receiver:)
      "#{tx_id_args(id)} -r #{receiver}"
    end

    def unratified_tx_args(**hsh)
      "-u #{counter_sign_tx_args(hsh)}"
    end

    def share
      self.response = JSON.parse(`#{share_cmd}`)
      puts "share cli result:"
      ap response
      extract_share_response
      tx_info
    end

    def grant(receiver:, quantity:)
      cmd = grant_cmd(receiver: receiver, quantity: quantity)
      resp = `#{cmd}`
      puts "cli response: #{resp}"
      @response = JSON.parse(resp)
      extract_grant_response
      tx_info
    end

    def tx_info
      str = ""
      str << "bitmark transfer ID: #{tx_id}, " if tx_id
      str << "pay transfer ID: #{pay_tx_id}, " if pay_tx_id
      str << "share ID: #{share_id}, " if share_id
      puts str
    end

    # share response:
    # {
    #         "txId" => "",
    #      "shareId" => "",
    #        "payId" => "",
    #     "payments" => {
    #         "BTC" => [
    #             [0] {
    #                 "currency" => "BTC",
    #                  "address" => "",
    #                   "amount" => "20000"
    #             }
    #         ],
    #         "LTC" => [
    #             [0] {
    #                 "currency" => "LTC",
    #                  "address" => "",
    #                   "amount" => "200000"
    #             }
    #         ]
    #     },
    #     "commands" => {
    #         "BTC" => "bitmark-wallet --conf ...",
    #         "LTC" => "bitmark-wallet --conf ..."
    #     }
    # }
    def extract_share_response
      # key denotes for instance method used, value denotes for key from cli response
      hsh = {
        "share_id=" => "shareId",
        "tx_id=" => "txId",
        "pay_tx_id=" => "payId",
      }
      extract_values_from_response(hsh)
      parse_payments
    end

    # grant response:
    # {
    #   "identity" => "eZW5AbiXJTKLna39vw5CAKDjwTxZsD8XozfLG754hRQDujz5HD",
    #   "grant" => "0920709725..."
    # }
    def extract_grant_response
      # key denotes for instance method used, value denotes for key from cli response
      # in other words, cli response result of "grant" will be saved into "tx_id"
      hsh = {
        "tx_id=" => "grant",
      }
      extract_values_from_response(hsh)
    end

    # provide hash transformation, key is the setter, value is response key
    def extract_values_from_response(hsh)
      hsh.each do |key, value|
        raise "response without key #{value}" unless response.key?(value)
        self.send(key, response[value]) if response[value]
      end
    end

    def parse_payments
      payments.keys.each { |key| self.payments[key] = response["commands"][key.to_s] }
    end

    def share_cmd
      cmd = "#{cli_base_cmd} share -t #{tx_id} -q #{share_amount}"
      puts "share command:"
      ap cmd
      cmd
    end

    def grant_cmd(id = share_id, before_blk = 0, receiver:, quantity:)
      "#{cli_base_cmd} grant -r '#{receiver}' -s #{id} -q #{quantity} -b #{before_blk}"
    end
  end

  module ClassMethods
    def tx_limit_time
      60 * 10
    end
  end
end
