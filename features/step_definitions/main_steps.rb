Given("I am on login page") do
  visit "/"
  expect(page).to have_selector(Selectors::LOGIN_FORM)
end

When("I continue as a guest") do
  find(Selectors::GUEST_BUTTON).click
end

When("I visit the main page") do
  visit mainpage_path
end

Then("I should see the welcome card") do
  expect(page).to have_content("Welcome to Queue")
end

Then("I should see the {string} button") do |label|
  expect(page).to have_content(label)
end

Then("I should see header {string}") do |text|
  expect(page).to have_content(text)
end

# ---- Session setup ----
Given("a live session exists") do
  venue = Venue.create!(name: "Feature Venue")
  @session = QueueSession.create!(
    venue: venue,
    created_at: 30.minutes.ago,
    playback_started_at: 25.minutes.ago,
    is_active: true,
    is_playing: true
  )
end

Given("that session has 1 unplayed song and a current track {string} by {string}") do |title, artist|
  QueueItem.create!(
    queue_session: @session,
    title: "Old Song",
    artist: "Someone",
    played_at: 10.minutes.ago
  )
  QueueItem.create!(
    queue_session: @session,
    title: title,
    artist: artist,
    is_currently_playing: true,
    played_at: nil
  )
end

Given("that session has 1 queued song but no current track") do
  QueueItem.create!(
    queue_session: @session,
    title: "Queued Only",
    artist: "Artist X",
    is_currently_playing: false,
    played_at: nil
  )
end

# ---- Assertions ----
Then("I should see that session's access code") do
  generated_code = @session.reload.access_code
  expect(generated_code).to be_present
  expect(page).to have_css(".access-code", text: generated_code)
end

Then("I should see a {string} link") do |label|
  expect(page).to have_link(label)
end
