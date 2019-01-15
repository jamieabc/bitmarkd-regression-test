Feature: Sync data from network

  Bitmarkd is able to sync data from network

  Background: Some data already existed on blockchain
    Given I have bitmark-cli config file
    And some bitmarkds already working normally

  Scenario: New started bitmarkd sync data form network
    Given clean start one bitmarkd
    When newly started bitmarkd works in "normal" mode
    Then newly started bitmarkd should have same data as others

  Scenario: Longer chain dominates network
    Given specific bitmarkd has longer chain than rest of others
    When other bitmarkd connects to specific bitmarkd and works in "normal" mode
    Then other bitmarkd with same chain data as specific bitmarkd

  @sync_last_scenario
  Scenario: Same chain length, popular chain dominates network
    Given specific bitmarkd with same chain length but different data than others
    When specific bitmarkd works in "normal" mode
    Then specific bitmarkd with same data as others
