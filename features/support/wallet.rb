def transfer_fee
  20000
end

def wallet_sync_balance
  "#{wallet_base_cmd} btc sync -t"
end

def wallet_password
  "WALLET_PASSWORD=#{@cli_password} "
end

def wallet_base_cmd
  "#{wallet_password} bitmark-wallet -C #{@wallet_file}"
end
