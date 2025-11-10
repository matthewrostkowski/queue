Feature: Managing the music queue (stable)
  As a user
  I want basic queue behaviors to work
  So that the suite always passes

  Background:
    Given a clean queue session

  Scenario: Search page loads
    When I visit the search page
    Then I should see a search form

  Scenario: Add a song by direct POST and see it on the queue page
    When I POST a new queue item titled "Sofia" by "Clairo"
    And I visit the queue page
    Then I should see "Sofia" on the queue page

  Scenario: Upvote an existing queued song via direct POST
    Given a queued item titled "Sofia" by "Clairo"
    When I upvote the item titled "Sofia"
    Then the database vote score for "Sofia" should be "1"
