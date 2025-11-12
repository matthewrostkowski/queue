# config/initializers/secret_key_base.rb
Rails.application.config.secret_key_base =
  ENV.fetch("SECRET_KEY_BASE") { "dev-fallback-secret-do-not-use-in-prod" }
