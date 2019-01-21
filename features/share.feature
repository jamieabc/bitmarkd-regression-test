Feature: Create share by bitmark-client

  User wants to use bitmark-cli to create share and give to others.

  Background: I am a bitmark-cli user
    Given I have bitmark-cli config file
    And some bitmarkds already working normally
    And I have a friend "Foo" with bitmark account

  Scenario: Create share
    Given I have asset "Grand palace woman" on blockchain
    When I split asset ownership into "50" shares
    Then asset become "50" shares

  # Scenario: Grant shares
  #   Given I have asset "The Blind Girl" with "100" shares
  #   When I grant my friend "Foo" with "30" shares
  #   Then "Foo" has "30" shares of "The Blind Girl"
  #   And I have "70" shares of "The Blind Girl"

  # Scenario: Swap shares
  #   Given I have "100" shares of asset "The School of Athens"
  #   And "Foo" has "200" shares of asset "Girl with a Pearl Earring"
  #   When I exchange "60" shares of mine for "30" shares of "Foo"
  #   Then I have "40" shares of "The school of Athens" and "30" shares of "Girl tiwh a pearl Earring"
  #   And "Foo" has "60" shares of "The school Athens" and "170" shares of "Girl with a Pearl Earring"
