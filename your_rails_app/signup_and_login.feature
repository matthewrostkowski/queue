@ui @auth
Feature: Sign up and sign in with email/password
  As a new user
  I want to create an account and sign in
  So that I can use Queue with my credentials

  Scenario: Sign up and land on main page
    Given I am logged out
    When I visit "/signup"
    And I fill in "user_email" with "newuser@example.com"
    And I fill in "user_password" with "mysecurepw"
    And I fill in "user_password_confirmation" with "mysecurepw"
    And I press "Create account"
    Then I should be on the main page

  Scenario: Sign in with email/password
    Given I am logged out
    And a general user exists with email "hello@example.com" and password "topsecret" and display name "Hello"
    When I visit "/login"
    And I fill in "email" with "hello@example.com"
    And I fill in "password" with "topsecret"
    And I press "Sign in"
    Then I should be on the main page
