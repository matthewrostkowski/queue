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

Then("I should be on the login page") do
  expect(page).to have_current_path("/", ignore_query: true)
  expect(page).to have_selector(Selectors::LOGIN_FORM)
end
