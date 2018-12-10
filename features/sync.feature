Feature: Sync data from network

  Bitmarkd is able to sync data from network
  
  Background: Some data already existed on blockchain
    Given 3 bitmarkds all have same blockchain data
    
  Scenario: Bitmarkd sync data form network
    Given 1 bitmarkd starts from empty data
    When bitmarkd is working normally
    Then after some time, bitmarkd should have same data as other nodes
    
  Scenario: Bitmarkd recover from forked data
    Given 1 bitmarkd has forked blockchain history
    When forked bitmarkd is working normally
    Then forked bitmarkd will have same records as other bitmarkds
