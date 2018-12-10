def minimum_required_balance
  1e9                           # 10 btc
end

def wallet_address
  'mnmAxmmcHGK7zUSQRF4LBNBzc1jgB7hWxd'
end

def beg_for_coins
  balance = get_wallet_btc_balance
  if balance < minimum_required_balance
    get_btc
  end
end

def get_wallet_btc_balance
  resp = wallet_sync_balance
  balance = get_balance_from_resp(resp)
end

def get_balance_from_resp(resp)
  resp.split("\n")
    .select { |str| str.include? "Balance:" }.first
    .split(" ")[1].to_i
end

def wallet_sync_balance
  `#{wallet_base_cmd} btc sync -t`
end

def wallet_password
  "WALLET_PASSWORD=#{@cli_password} "
end

def wallet_base_cmd
  "#{wallet_password} bitmark-wallet -C #{@wallet_file}"
end
