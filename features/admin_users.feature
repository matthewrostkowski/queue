Feature: Manage users
  As an admin
  I want to view all users and change roles
  So that I can manage access

  Background:
    Given I am logged in as an admin
    And a user exists with email "alpha@example.com" and role "user"
    And a user exists with email "beta@example.com" and role "host"

  Scenario: Admin can see everyone but cannot act on self
    When I visit the admin users page
    Then I should see "alpha@example.com"
    And I should see "beta@example.com"
    And I should see my own email
    And in my row I should see "(no self-actions)"

  Scenario: Promote another user to admin
    When I visit the admin users page
    And I promote "alpha@example.com" to admin
    Then the user "alpha@example.com" should have role "admin"

  Scenario: Demote a host to user
    When I visit the admin users page
    And I demote "beta@example.com" to user
    Then the user "beta@example.com" should have role "user"
