Feature: Sync data from network

  Bitmarkd is able to sync data from network

  Background: Some data already existed on blockchain
    Given I have bitmark-cli config file
    And some bitmarkds already working normally

  Scenario: New started bitmarkd sync data form network
    Given clean start one bitmarkd
    When newly started bitmarkd works in normal mode
    Then newly started bitmarkd should have same data as others

  @sync_last_scenario
  Scenario: Longer chain dominates network
    Given some bitmarkds has longer chain than rest of others
    When other bitmarkd connects to specific bitmarkd and works in normal mode
    Then other bitmarkd with same chain data as specific bitmarkd
