Feature: Create tx by bitmark-cli

  User wants to use bitmark-cli to transfer assets.

  Background: I am a bitmark-cli user
    Given I have bitmark-cli config file
    And wallet has enough balance to pay
    And I have a friend "Foo" with bitmark account
    
  Scenario: Unratified transfer digital asset to my friend
    Given I have asset name "The Starry Night" on blockchain
    When I unratified transfer asset to my friend "Foo"
    And pay for transfer fee
    And wait transfer become valid
    Then asset first owner is "me"
    And asset latest owner is "Foo"
    
  Scenario: Counter-sign transfer digital asset to my friend
    Given I have asset name "The Harvest" on blockchain
    When I counter-sign transfer asset to my friend "Foo"
    And "Foo" also counter-signs transfer
    And pay for transfer fee
    And wait transfer become valid
    Then asset first owner is "me"
    And asset latest owner is "Foo"
