Feature: Create issue by bitmark-cli

  User wants to use bitmark-cli to create an issue for their digital assets.

  Background: I am a bitmark-cli user
    Given I have bitmark-cli config file
    And some bitmarkds already working normally

  Scenario Outline: Issue digital asset(s)
    Given I have asset <name>, amount <amount>, metadata <key> to be <value>
    When I issue
    Then I have valid asset stored on blockchain
    And with name <name>, amount <amount>, metadata <key> to be <value>

    Examples: Successful examples
      Necessary fields are provided

      | name     | amount | key     | value   |
      | "Irises" | "1"    | "owner" | "Bob"   |
      | ""       | "1"    | "owner" | "Alice" |

  Scenario Outline: Issue with missing parameters
    Given I have asset <name>, amount <amount>, metadata <key> to be <value>
    When I issue
    Then I failed with cli error message <error message>

    Examples: Missing necessary parameters
      asset name and metadata are both required.

      | name       | amount | key     | value   | error message            |
      | "Failed 1" | "1"    | ""      | ""      | "metadata is not map"    |
      | "Failed 2" | "1"    | "owner" | ""      | "metadata is not map"    |
      | "Failed 3" | "1"    | ""      | "Sam"   | "metadata is not map"    |

  Scenario: Issue same asset twice should pay
    Given I have asset "The Mona Lisa", amount "1", metadata "owner" to be "Hank"
    When I issue first time and wait for it become valid
    And I issue same asset second time
    Then I need to pay for second issue
