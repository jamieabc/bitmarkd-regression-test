Feature: Create tx by bitmark-cli

  User wants to use bitmark-cli to transfer assets.

  Background: I am a bitmark-cli user
    Given I have bitmark-cli config file
    And latest wallet balance is able to do transfer
    And I have a friend "Foo" with bitmark account
    
  Scenario: Unratified transfer digital asset to my friend
    Given I have asset name "my precious asset" on blockchain
    When I unratified transfer asset to my friend "Foo"
    And pay for transfer fee and wait it become valid
    Then asset first owner is "me"
    And asset latest owner is "Foo"
    
  Scenario: Counter-sign transfer digital asset to my friend
    Given I have asset name "my valuable asset" on blockchain
    When I counter-sign transfer of asset to "Foo"
    And "Foo" counter-signs the transfer
    And pay for transfer fee and wait it become valid
    Then asset first owner is "me"
    And asset latest owner is "Foo"
