# on mac, default bitcoin data directory is at ~/Library/Application\ Support/bitcoin
# on linux, default bitcoin data directory is at ~/.bitcoin

# remember to put bitcoin.conf into default directory,
# or set datadir in bitcoin-cli arguments

def btc_address
  'mnmAxmmcHGK7zUSQRF4LBNBzc1jgB7hWxd'
end

def get_some_coins
  `#{bitcoin}`
end

def btc_cli_base_cmd
  'bitcoin-cli -conf=bitcoin.conf'
end
