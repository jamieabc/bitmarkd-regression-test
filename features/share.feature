Feature: Create share by bitmark-client

  User wants to use bitmark-cli to create share and give to others.

  Background: I am a bitmark-cli user
    Given I have bitmark-cli config file
    And some bitmarkds already working normally

  Scenario: Create share
    Given I have asset name "Grand palace woman" on blockchain
    When I split asset ownership into "50" shares
    Then asset become "50" shares
