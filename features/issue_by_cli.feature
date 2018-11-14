Feature: Create an issue record by bitmark-cli tool

  The user wants to use bitmark-cli to create an issue to record digital asset.

  Background:
    Given I am a user of bitmark-cli

  Scenario: Issue a digital asset successfully
    Given I have a digital asset named "my first asset"
    And I have only "1" amount
    And I want metadata of "owner" to be "Bob"
    When I issue
    Then I can have a "confirmed" record on blockchain
    And asset name is "my first asset"
    And asset metadata of "owner" is "Bob"
    And asset quantity is "1"

  Scenario: Issue a digital asset without name
    Given I have a digital asset
    And I have only "1" amount
    And I want metadata of "owner" to be "Alice"
    When I issue
    Then I got an error message of "asset name is required"

  Scenario: Issue a digital asset without quantity
    Given I have a digital asset named "my second asset"
    And I want metadata of "owner" to be "James"
    When I issue
    Then I can have a "confirmed" record on blockchain
    And asset name is "my second asset"
    And asset metadata of "owner" is "James"
    And asset quantity is "1"

  Scenario: Issue a digital asset without metadata
    Given I have a digital asset named "my third asset"
    And I have only "1" amount
    When I issue
    Then I got an error message of "metadata is required"
