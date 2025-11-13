Feature: Admin dashboard
  As an admin
  I want to see high-level stats
  So I can monitor the system

  Background:
    Given I am logged in as an admin

  Scenario: See overall counts
    Given there are 2 users in the system
    And there are 1 venues
    And there are 1 active queue sessions
    And there are 3 songs
    When I visit the admin dashboard
    Then I should see "Total Users"
    And I should see the number "2"
    And I should see "Total Venues"
    And I should see the number "1"
    And I should see "Active Sessions"
    And I should see the number "1"
    And I should see "Total Songs"
    And I should see the number "3"
