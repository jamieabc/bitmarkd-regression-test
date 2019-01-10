This is a regression test cases using Cucumber framework to write.

It uses ruby to write.

Install ruby environment form [here](https://www.ruby-lang.org/zh_tw/documentation/installation/)
Instal ruby gem by `gem install cucumber`

Run tests by `cucumber`

# Execution environment


All of following settings can be modified at `features/support/env.rb`, some assumptions are made:

1. At least 5 bitmarkds form a cluster
  - Configurations are denoted by `cli1.conf`, `cli2.conf`, `cli3.conf`, `cli4.conf`, `cli5.conf` and places at project root directory
  - Bitmarkd RPC ports are `2130`, `2230`, `2330`, `2430`, `2530`
  - Node 3 (port `2330`) will be used for most operations, node 4 (port `2430`) will be used for fork recovery
  - Each bitmarkd runs by config file name noted as number, e.g. `bitmarkd1.conf`, `bitmarkd2.conf`, tc.
  - Bitmarkd directory is stored at `${HOME}/.config/bitmarkd1`, `${HOME}/.config/bitmarkd2`, etc.

2. Related services of `recorderd`, `bitcoind`, `litecoind` are running
  - `recorderd` connects to some bitmarkds
  - `bitcoind` and `litecoind` can be controllerd by their command line tools

3. `bitmark-wallet` is running
  - Configuration file is `wallet.conf` and placed at project root directory

4. `bitmark-cli` password is `12345678`
