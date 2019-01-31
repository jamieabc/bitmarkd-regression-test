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

    def cli_base_cmd(identity = default_identity)
      "#{cli} -c #{cli_conf} -i '#{identity}' -p #{password}"
    end

    def identities
      resp = JSON.parse(`#{cli_base_cmd} info`)
      resp["identities"].map { |i| i["name"] }
    end

    def setup_issue_args(name:, meta:, quantity:)
      @asset_name = name
      @asset_quantity = quantity
      @asset_meta = meta
    end

    # genesis block record is currently not on chain, so when test sync between different
    # chains, program hangs because it cannot not distinguish if two chains differ from
    # the beginning are same or not.
    # In order to test sync features, I manually setup an issue record that is same
    # for all tests, think it as a virtual genesis block record.
    def issue_first_record
      meta = {
        "owner" => "me",
      }
      setup_issue_args(name: "first asset", meta: meta, quantity: 1)
      @fingerprint = "first issue record"

      issue(again: false, first_record: true)
    end

    def issue(again: false, first_record: false)
      self.response = nil

      # generate new issue or use previous one
      if again && !prev_cmd.nil?
        # clear previous existing result
        cmd = prev_cmd
      else
        cmd = issue_cmd(first_record)
        self.prev_cmd = cmd
      end

      puts "issue command: #{cmd}"
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

    def issue_cmd(first_record = false)
      "#{cli_base_cmd} create #{issue_args(first_record)} 2>&1"
    end

    def issue_args(first_record)
      gen_fingerprint if first_record == false
      "#{asset_args} #{meta_args} -f \"#{fingerprint}\""
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
      puts "transfer cli result: #{response}"
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
    def balance(id = share_id)
      cmd = balance_cmd(id)
      resp = JSON.parse(`#{cmd}`)
      puts "cli balance response: #{resp}"
      self.share_info = resp["balances"]
      item = share_info.first
      [item["shareId"], item["confirmed"]]
    end

    # balance will return all balances from that point, so limit count to 1
    def balance_cmd(share_id)
      cmd = "#{cli_base_cmd} balance -s #{share_id} -c 1"
      puts "balance command: #{cmd}"
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
      puts "pay result: #{json}"
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

    def counter_sign(receiver)
      cmd = counter_sign_cmd(receiver)
      puts "counter sign command: #{cmd}"
      self.response = JSON.parse(`#{cmd}`)
      puts "counter sign cli result: #{response}"
      extract_transfer_response(false)
    end

    def counter_sign_cmd(receiver)
      "#{cli_base_cmd(receiver)} countersign -t #{tx_id} 2>&1"
    end

    def transfer_cmd(args)
      cmd = "#{cli_base_cmd} transfer #{args} 2>&1"
      puts "transfer command: #{cmd}\n"
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
      puts "share cli result: #{response}"
      extract_share_response
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
    #     {
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
      hsh = {
        "share_id=" => "shareId",
        "tx_id=" => "txId",
        "pay_tx_id=" => "payId",
      }
      extract_values_from_response(hsh)
      parse_payments
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
      "#{cli_base_cmd} share -t #{tx_id} -q #{share_amount}"
    end
  end

  module ClassMethods
    def tx_limit_time
      60 * 10
    end
  end
end
