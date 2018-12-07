Feature: Fork recovery

  Bitmarkd should be able to recover from forked history
  
  Background: Some data already existed on blockchain
    Given 3 bitmarkds has same blockchain data
    Given 1 bitmarkd has different blockchain data then others
    
    #pre generate by test case 

# use run-bitmarkd delete-down #
# stop 1, delete some block
# stop other, detel some and create new 
  
  Scenario: Bitmarkd is able to recover from fork
    Given One bitmarkd has forked blockchain history
    When Forked bitmarkd connects to other bitmarks
    Then Forked bitmarkd will have same records as other bitmarkds
    
Scenario: sync from missing
