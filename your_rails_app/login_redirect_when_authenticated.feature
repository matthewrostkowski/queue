@ui @auth @redirect
Feature: Redirect authenticated users away from login
  As a signed-in user
  I should not see the login page again
  So that I land on the main page when visiting / or /login

  Background:
    Given I am logged in as "Cucumber Guest"

  Scenario: Visiting /login when already signed in
    When I visit "/login"
    Then I should be on the main page

  Scenario: Visiting / (root) when already signed in
    When I visit "/"
    Then I should be on the main page
