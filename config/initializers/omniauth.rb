OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

# Only configure Google OAuth if credentials are provided
if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID"),
    ENV.fetch("GOOGLE_CLIENT_SECRET"),
    {
        scope: "email,profile",
        prompt: "select_account"
    }
  end
else
  Rails.logger.warn "⚠️  Google OAuth credentials not configured - skipping Google OAuth setup"
end
