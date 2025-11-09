source "https://rubygems.org"
ruby "3.3.4"

gem "rails", "8.0"
gem "puma",  "~> 6.6"

# Timezone helpers (from course list)
gem "tzinfo"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw]

group :development, :test do
  gem "byebug"
  gem "listen",       "~> 3.8"
  gem "guard-rspec",  "~> 4.7"

  # Testing stack
  gem "rspec-rails"
  gem "cucumber-rails", require: false
  gem "capybara", "~> 3.40"
  gem "database_cleaner-active_record"
  gem 'shoulda-matchers', '~> 5.0'
  gem "simplecov", "~> 0.22", require: false
  gem "webmock",   "~> 3.23"

  # Request helpers
  gem "rack-test", "~> 2.1"

  # Dev/Test DB
  gem "sqlite3", "~> 2.1"
end

group :production do
  gem "pg", "~> 1.1"
end

gem "bootsnap", require: false
gem "bcrypt", "~> 3.1"