source "https://rubygems.org"
ruby "3.3.8"

gem "rails", "8.0"
gem "puma", "~> 6.6"
gem "faraday"
gem "dotenv-rails", groups: [:development, :test]

# Timezone helpers (from course list)
gem "tzinfo"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw]

# Faster boot
gem "bootsnap", require: false

# --- Development & Test ---
group :development, :test do
  gem "byebug"
  gem "listen", "~> 3.8"

  # Testing stack
  gem "rspec-rails"
  gem "cucumber-rails", require: false
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
  gem 'shoulda-matchers', '~> 5.0'
  gem "simplecov", "~> 0.22", require: false
  gem "guard-rspec", "~> 4.7"
  gem "rails-controller-testing"

  # Request helpers
  gem "rack-test", "~> 2.1"

  # Dev/Test DB
  gem "sqlite3", "~> 2.1"

  # Authentication
  gem "omniauth", "~> 2.1"
  gem "omniauth-rails_csrf_protection"
  gem "omniauth-google-oauth2", "~> 1.1"
end

# --- Test only ---
group :test do
  gem "webmock", "~> 3.23"
  # gem "webdrivers" # uncomment only if you need it for ChromeDriver mgmt
end

# --- Production ---
group :production do
  gem "pg", "~> 1.1"
end

gem "bootsnap", require: false
gem "bcrypt", "~> 3.1"

# TODO: Move from CDN to tailwindcss-rails build once asset pipeline is set up
# gem "tailwindcss-rails", "~> 4.4"
