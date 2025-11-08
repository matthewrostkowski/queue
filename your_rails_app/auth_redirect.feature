@ui @auth
Feature: Redirect unauthenticated users to login
  As a visitor
  I want to be redirected to the login page
  So that protected pages are not accessible without signing in

  Background:
    Given I am logged out

  Scenario: Visiting main page requires authentication
    When I visit "/mainpage"
    Then I should be on the login page

  Scenario: Visiting search page requires authentication
    When I visit "/search"
    Then I should be on the login page

  Scenario: Visiting profile page requires authentication
    When I visit "/profile"
    Then I should be on the login page

  Scenario: Visiting scan page requires authentication
    When I visit "/scan"
    Then I should be on the login page
