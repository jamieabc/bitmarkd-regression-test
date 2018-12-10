# on mac, default bitcoin data directory is at ~/Library/Application\ Support/bitcoin
# on linux, default bitcoin data directory is at ~/.bitcoin

# remember to put bitcoin.conf into default directory,
# or set datadir in bitcoin-cli arguments

def get_btc
  `#{btc_cli_base_cmd} sendtoaddress #{btc_address} 50`

  # make sure record is put onto blockchain
  mine_block(3)
end

# this value needs to be synced with wallet address
def btc_address
  'mnmAxmmcHGK7zUSQRF4LBNBzc1jgB7hWxd'
end

def mine_block(count)
  `#{btc_cli_base_cmd} generate #{count}`
end

def btc_cli_base_cmd
  'bitcoin-cli -conf=bitcoin.conf'
end
