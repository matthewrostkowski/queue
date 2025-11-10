# features/support/capybara.rb
require "capybara/cucumber"

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 3
