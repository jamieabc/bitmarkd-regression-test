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
  #   Given I have "200" shares of asset "The Blind Girl"
  #   When I grant "Foo" with "30" shares
  #   Then "Foo" has "30" shares of asset
  #   And I have "70" shares of asset
  #   And I am not allowed to grant "100" shares of asset to "Foo"

  # Scenario: Swap shares
  #   Given I have "100" shares of asset A - "The School of Athens"
  #   And "Foo" has "200" shares of asset B - "Girl with a Pearl Earring"
  #   When I exchange "60" shares of asset A for "30" shares of asset B
  #   Then I have "40" shares of asset A and "30" shares of asset B
  #   And "Foo" has "60" shares of asset A and "170" shares of asset B


# double spend?
    # fork and an transaction is missing, transfer again
