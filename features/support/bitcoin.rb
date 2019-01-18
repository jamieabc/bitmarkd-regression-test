# on mac, default bitcoin data directory is at ~/Library/Application\ Support/bitcoin
# on linux, default bitcoin data directory is at ~/.bitcoin

# remember to put bitcoin.conf into default directory,
# or set datadir in bitcoin-cli arguments
class BTC
  attr_reader :addr

  def initialize(addr = "mnmAxmmcHGK7zUSQRF4LBNBzc1jgB7hWxd")
    @@cmd = "bitcoin-cli"
    @addr = addr
  end

  def send_tokens(custom_addr = addr)
    `#{@@cmd} sendtoaddress #{custom_addr} 50`

    # make sure record is put onto blockchain
    self.class.mine
  end

  def self.mine(blk_count = 6)
    `#{@@cmd} generatetoaddress #{blk_count} $(bitcoin-cli getnewaddress)`
  end
end
