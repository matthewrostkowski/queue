Feature: Canonical email login rules
  Scenario: Sign up then login with variants (case, dots, plus)
    Given I am logged out
    And I sign up with email "User.Name+shop@Example.com" and password "heresecret"
    When I log out
    And I log in with email "username@example.com" and password "heresecret"
    Then I should be on the main page
    When I log out
    And I log in with email "user.name@example.com" and password "heresecret"
    Then I should be on the main page
    When I log out
    And I log in with email "username+work@example.com" and password "heresecret"
    Then I should be on the main page
