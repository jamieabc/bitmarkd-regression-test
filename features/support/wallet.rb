class Wallet
  attr_reader :conf, :password, :ltc_conf, :min_btc_balance

  def initialize
    @conf = "#{ENV["HOME"]}/.config/wallet/wallet.conf"
    @password = "12345678"
    @min_btc_balance = 1e9      #10 btc
    btc_balance
  end

  def exist?
    File.exist?(conf)
  end

  def prepare_tokens(crypto)
    crypto.send_tokens if btc_balance < min_btc_balance
  end

  def pay(crypto, pay_id, pay_addr, amount)
    raise "invalid payments #{crypto}" unless supported.include?(crypto.upcase)
    cmd = "#{base_cmd} #{crypto.downcase} --testnet sendmany --hex-data " \
    "'#{pay_id}' '#{pay_addr},#{amount}'"
    puts "pay command: #{cmd}"
    `#{cmd}`
  end

  def btc_balance
    resp = sync_btc_balance
    parse_btc_balance(resp)
  end

  def btc_enough?
    btc_balance >= min_btc_balance
  end

  private

  def parse_btc_balance(resp)
    resp.split("\n")
      .select { |str| str.include?("Balance:") }.first
      .split(" ")[1].to_i
  end

  def sync_btc_balance
    `#{base_cmd} btc sync -t`
  end

  def cmd_prefix
    "WALLET_PASSWORD=#{password}"
  end

  def base_cmd
    "#{cmd_prefix} bitmark-wallet -C #{conf}"
  end

  def supported
    %w(BTC LTC)
  end

  def self.btc_addr
    "mnmAxmmcHGK7zUSQRF4LBNBzc1jgB7hWxd"
  end

  def self.ltc_addr
    "mjPkDNakVA4w4hJZ6WF7p8yKUV2merhyCM"
  end
end
