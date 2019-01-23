Feature: Create issue by bitmark-cli

  User wants to use bitmark-cli to create an issue for their digital assets.

  Background: I am a bitmark-cli user
    Given I have bitmark-cli config file
    And some bitmarkds already working normally

  Scenario Outline: Issue digital asset(s)
    Given I have digital asset name <asset name>
    And amount <asset amount>, metadata <meta key> to be <meta value>
    When I issue
    Then I have valid asset stored on blockchain
    And with name <asset name>, amount <asset amount>, metadata <meta key> to be <meta value>

    Examples: Successful examples
      Necessary fields are provided

      | asset name | asset amount | meta key | meta value |
      | "Irises"   | "1"          | "owner"  | "Bob"      |

  Scenario Outline: Issue with missing parameters
    Given I have digital asset name <asset name>
    And amount <asset amount>, metadata <meta key> to be <meta value>
    When I issue
    Then I failed with cli error message <error message>

    Examples: Missing necessary parameters
      asset name and metadata are both required.

      | asset name | asset amount | meta key | meta value | error message            |
      | ""         | "1"          | "owner"  | "James"    | "asset name is required" |
      | "Failed 1" | "1"          | ""       | ""         | "metadata is not map"    |
      | "Failed 2" | "1"          | "owner"  | ""         | "metadata is not map"    |
      | "Failed 3" | "1"          | ""       | "Sam"      | "metadata is not map"    |

  Scenario: Issue same asset twice should pay
    Given I have digital asset name "The Mona Lisa"
    And amount "1", metadata "owner" to be "Hank"
    When I issue first time and wait for it become valid
    And I issue same asset second time
    Then I need to pay for second issue
