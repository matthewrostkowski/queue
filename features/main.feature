Feature: Main page shows welcome card and live queues
  As a visitor
  I want to see the welcome card and any live sessions
  So that I can join a queue

  Scenario: Empty state
    Given I am on login page
    When I continue as a guest
    Then I should be on the main page
    Then I should see the welcome card
    And I should see the "Scan QR" button
    And I should see the "🔍 Search Songs" button
    And I should see "No active sessions"

  Scenario: One live session with a current track
    Given I am on login page
    When I continue as a guest
    Given a live session exists
    And that session has 1 unplayed song and a current track "Current Jam" by "DJ Test"
    When I visit the main page
    Then I should see header "Live Queues"
    And I should see that session's access code
    And I should see "1 song"
    And I should see "Current Jam — DJ Test"
    And I should see a "Join Queue" link

  Scenario: Live session with nothing playing
    Given I am on login page
    When I continue as a guest
    Given a live session exists
    And that session has 1 queued song but no current track
    When I visit the main page
    Then I should see that session's access code
    And I should see "Nothing playing"
