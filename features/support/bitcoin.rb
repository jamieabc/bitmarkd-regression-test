# on mac, default bitcoin data directory is at ~/Library/Application\ Support/bitcoin
# on linux, default bitcoin data directory is at ~/.bitcoin

# remember to put bitcoin.conf into default directory,
# or set datadir in bitcoin-cli arguments
class BTC
  attr_reader :addr

  def initialize(addr)
    @@conf = "bitcoin.conf"
    @@cmd = "bitcoin-cli -conf=#{@@conf}"
    @addr = addr
  end

  def send_btc_to(addr)
    `#{@@cmd} sendtoaddress #{addr} 50`

    # make sure record is put onto blockchain
    self.class.mine
  end

  def self.mine(blk_count = 6)
    `#{@@cmd} generatetoaddress #{blk_count} $(bitcoin-cli getnewaddress)`
  end
end
