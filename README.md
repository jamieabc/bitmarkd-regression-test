This is a set of regression test cases written in Ruby, use Cucumber framework to execute.

Install ruby environment form [here](https://www.ruby-lang.org/zh_tw/documentation/installation/)

Install ruby gem by command: `gem install cucumber faker`

Run tests by command: `cucumber -g` at project root directory.

# Execution environment

All of following settings can be modified at `features/support/env.rb`, some pre-conditions are made:

1. At least 5 bitmarkds form a cluster
  - `bitmarkd-cli` configurations are denoted by `cli1.conf`, `cli2.conf`, `cli3.conf`, `cli4.conf`, `cli5.conf` and places at project root directory
  - Bitmarkd RPC ports are `2130`, `2230`, `2330`, `2430`, `2530`
  - Node 3 (port `2330`) will be used for most operations, node 4 (port `2430`) will be used for fork recovery test
  - Each `bitmarkd` config file should include its order, e.g. `bitmarkd1.conf`, `bitmarkd2.conf`, etc.
  - Bitmarkd directories are set to `${HOME}/.config/bitmarkd1`, `${HOME}/.config/bitmarkd2`, etc.

2. Related services of `recorderd`, `bitcoind`, `litecoind` are running
  - `recorderd` connects to some bitmarkds
  - `bitcoind` and `litecoind` can be controllerd by their command line tools
  - `bitcoind` uses port `18002`
  - `litecoind` uses port `19002`

3. `bitmark-wallet` is running
  - Configuration file is `wallet.conf` and placed at project root directory
  - `wallet.conf` at path `~/.config/wallet/wallet.conf`, be ware to change bitcoin/litecoin node address to `127.0.0.1` (originally was set to test server)

4. `bitmark-cli` password is `12345678`, with two pre-defined users: `regression test user` and `Foo`
