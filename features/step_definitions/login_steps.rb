require_relative "../support/selectors"

Given("I am on the login page") do
  visit "/"
  expect(page).to have_selector(Selectors::LOGIN_FORM)
end

When("I continue as guest") do
  find(Selectors::GUEST_BUTTON).click
end

Then("I should be on the main page") do
  expect(page).to have_current_path("/mainpage", ignore_query: true)
  expect(page).to have_selector(Selectors::MAIN_WELCOME)
end

Then("I should see my guest name on the page") do
  expect(page.find(Selectors::CURRENT_USER).text).to match(/^Guest\b/)
end

When("I logout") do
  click_button "Logout"
end

Given("I am logged out") do
  Capybara.reset_sessions!
  begin
    page.driver.submit :delete, "/logout", {}
  rescue StandardError
  end
end

When('I visit {string}') do |path|
  visit path
end

Then('I should be on the login page') do
  expect(page).to have_current_path('/login', ignore_query: true)
  expect(page).to have_selector('[data-testid="login-form"]')
end

# authenticate user when the session is available
Given('I am logged in as {string}') do |name|
  page.driver.submit :post, "/session", { provider: "guest", display_name: name }
  visit "/mainpage"
  expect(page).to have_current_path("/mainpage", ignore_query: true)
end

Given("a general user exists with email {string} and password {string} and display name {string}") do |email, pw, name|
  User.create!(auth_provider: "general_user", email: email.downcase, password: pw, password_confirmation: pw, display_name: name)
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I press {string}') do |label|
  click_button label
end