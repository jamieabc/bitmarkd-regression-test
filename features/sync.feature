Feature: Sync data from network

  Bitmarkd is able to sync data from network
  
  Background: Some data already existed on blockchain
    Given I have bitmark-cli config file
    And some bitmarkds already working normally
    
  @sync_first_scenario
  Scenario: Bitmarkd sync data form network
    Given I clean start a bitmarkd
    When my newly started bitmarkd is working normally
    Then my newly started bitmarkd should have same data as other nodes
    
  @sync_last_scenario
  Scenario: Bitmarkd recover from forked data
    Given my bitmarkd has forked blockchain history
    When forked bitmarkd is working normally
    Then forked bitmarkd will have same records as other nodes 
