Feature: User Profile Page
  As a user
  I want to see how many songs I've added and upvotes earned
  So that I can track my contribution to the queue

  Background:
    Given I am logged in as "TestUser"
    And a venue "Blue Note" with an active queue session exists

  Scenario: View profile with no activity
    When I visit my profile page
    Then I should see my username "@TestUser"
    And I should see "0" songs queued
    And I should see "0" total upvotes
    And I should see "You haven't queued any songs yet"

  Scenario: View profile with one queued song
    Given I have queued the song "Blinding Lights" by "The Weeknd"
    And that song has received 5 upvotes
    When I visit my profile page
    Then I should see "1" songs queued
    And I should see "5" total upvotes
    And I should see the song "Blinding Lights"
    And I should see "5" upvotes for that song

  Scenario: View profile with multiple songs and varying upvotes
    Given I have queued the following songs:
      | title           | artist       | upvotes | status  |
      | Blinding Lights | The Weeknd   | 10      | played  |
      | Levitating      | Dua Lipa     | 5       | pending |
      | As It Was       | Harry Styles | 8       | pending |
    When I visit my profile page
    Then I should see "3" songs queued
    And I should see "23" total upvotes
    And I should see all 3 songs listed

  Scenario: View profile shows song status badges
    Given I have queued the song "Blinding Lights" by "The Weeknd" with status "played"
    When I visit my profile page
    Then I should see a status badge showing "Played"

  Scenario: View profile shows dynamic pricing
    Given I have queued the song "Blinding Lights" by "The Weeknd"
    And that song has a base price of "$3.99"
    When I visit my profile page
    Then I should see a price displayed for that song

  Scenario: Unauthenticated user cannot view profile
    Given I am not logged in
    When I try to visit the profile page
    Then I should see an unauthorized message