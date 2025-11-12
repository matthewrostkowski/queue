# --- Authentication shortcuts ---

Given("I am logged in as an admin") do
  # Ensure an admin exists
  @current_admin = User.find_by(email: "admin@example.com") ||
                   User.create!(
                     display_name: "Admin",
                     email: "admin@example.com",
                     password: "password",
                     auth_provider: "general_user",
                     role: :admin
                   )

  # Visit the real login page and sign in
  visit login_path

  # If your page has multiple "Sign in" buttons (e.g., Google), scope to the form
  # Adjust the selectors/labels to match your markup.
  if page.has_css?("[data-testid='login-form']")
    within("[data-testid='login-form']") do
      fill_in "Email", with: @current_admin.email
      fill_in "Password", with: "password"
      click_button "Sign in"
    end
  else
    fill_in "Email", with: @current_admin.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end

# --- Data setup helpers ---

Given("there are {int} users in the system") do |n|
  # ensure at least n users exist (admin may already be present)
  existing = User.count
  (n - existing).times do |i|
    User.create!(display_name: "U#{i+1}", email: "user#{i+1}@example.com",
                 password: "password", auth_provider: "local", role: :user)
  end
end

Given("there are {int} venues") do |n|
  (n - Venue.count).times { |i| Venue.create!(name: "Venue #{i+1}") }
end

Given("there are {int} active queue sessions") do |n|
  venues = Venue.all.to_a
  n.times do |i|
    v = venues[i] || Venue.create!(name: "Auto Venue #{i+1}")
    QueueSession.create!(venue: v, is_active: true, is_playing: true,
                         playback_started_at: 10.minutes.ago)
  end
end

Given("there are {int} songs") do |n|
  (n - Song.count).times do |i|
    Song.create!(title: "Song #{i+1}", artist: "Artist #{i+1}")
  end
end

Given("a user exists with email {string} and role {string}") do |email, role|
  User.find_or_create_by!(email: email) do |u|
    u.display_name = email.split("@").first.capitalize
    u.password = "password"
    u.auth_provider = "local"
    u.role = role
  end
end

# --- Navigation ---

When("I visit the admin dashboard") do
  visit admin_dashboard_path
end

When("I visit the admin users page") do
  visit admin_users_path
end

# --- Assertions ---

Then("I should see the number {string}") do |num|
  expect(page).to have_content(num)
end

Then("I should see my own email") do
  expect(page).to have_content(@current_admin.email)
end

Then("in my row I should see {string}") do |text|
  # Find the row that contains the admin's email and assert text there
  row = page.find("tr", text: @current_admin.email)
  expect(row).to have_content(text)
end

Then("the user {string} should have role {string}") do |email, role|
  u = User.find_by(email: email)
  expect(u&.role).to eq(role)
end

# --- Row-scoped actions (works with button_to labels) ---

When("I promote {string} to admin") do |email|
  row = page.find("tr", text: email)
  # button_to generates <form> with <input type=submit value="Admin"> or a <button> with text "Admin"
  if row.has_button?("Admin")
    row.click_button("Admin")
  else
    row.click_link("Admin") # in case you're still using link_to with turbo
  end
end

When("I demote {string} to user") do |email|
  row = page.find("tr", text: email)
  if row.has_button?("Demote")
    row.click_button("Demote")
  else
    row.click_link("Demote")
  end
end
