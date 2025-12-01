# features/step_definitions/host_routing_steps.rb

Given('the following users exist:') do |table|
  table.hashes.each do |row|
    User.create!(
      email: row['email'],
      password: row['password'],
      password_confirmation: row['password'],
      display_name: row['display_name'],
      auth_provider: 'general_user',
      role: row['role']
    )
  end
end

Given('I am logged in as a host with email {string}') do |email|
  user = User.find_by!(email: email)
  visit login_path
  fill_in 'email', with: email
  fill_in 'password', with: 'password123'
  click_button 'Log In'
end

Given('I am logged in as a user with email {string}') do |email|
  user = User.find_by!(email: email)
  visit login_path
  fill_in 'email', with: email
  fill_in 'password', with: 'password123'
  click_button 'Log In'
end

Given('I am logged in as an admin with email {string}') do |email|
  user = User.find_by!(email: email)
  visit login_path
  fill_in 'email', with: email
  fill_in 'password', with: 'password123'
  click_button 'Log In'
end

When('I visit the login page') do
  visit login_path
end

When('I visit the host venues page') do
  visit host_venues_path
end

When('I visit the new host venue page') do
  visit new_host_venue_path
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I press {string}') do |button|
  click_button button
end

When('I press {string} or {string}') do |button1, button2|
  begin
    click_button button1
  rescue Capybara::ElementNotFound
    click_button button2
  end
end

Then('I should be on the host venues page') do
  expect(current_path).to eq(host_venues_path)
end

Then('I should be on the host venue page') do
  expect(current_path).to match(%r{^/host/venues/\d+$})
end

Then('I should be on the main page') do
  expect(current_path).to eq(mainpage_path)
end

Then('I should be on the admin dashboard page') do
  expect(current_path).to eq(admin_dashboard_path)
end

Then('I should be on the login page') do
  expect(current_path).to eq(login_path)
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should see {string} or {string}') do |text1, text2|
  expect(page).to have_content(text1).or have_content(text2)
end

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end

Then('I should see a 6-digit join code') do
  expect(page).to have_content(/\b\d{6}\b/)
end