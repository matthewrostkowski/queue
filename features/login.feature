@ui @auth
Feature: Login
  As a patron
  I want to sign in
  So that I can use Queue at a venue

  Scenario: Sign in as guest, land on Main, then logout back to Login
    Given I am on the login page
    When I continue as guest
    Then I should be on the main page
    And I should see my guest name on the page
    When I logout
    Then I should be on the login page
