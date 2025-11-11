# spec/requests/canonical_email_spec.rb
require "rails_helper"

RSpec.describe "Canonical email rules", type: :request do
  it "treats case-insensitive, ignores dots and plus-tag as the same account" do
    post users_path, params: {
      user: {
        email: "User.Name+shopping@Example.COM",
        password: "supersecret",
        password_confirmation: "supersecret",
        display_name: "User"
      }
    }
    expect(response).to redirect_to(mainpage_path)
    user = User.last
    expect(user.canonical_email).to eq("username@example.com") 

    delete logout_path

    post session_path, params: { provider: "general_user", email: "USERNAME@example.com", password: "supersecret" }
    expect(response).to redirect_to(mainpage_path)

    delete logout_path

    post session_path, params: { provider: "general_user", email: "user.name@example.com", password: "supersecret" }
    expect(response).to redirect_to(mainpage_path)

    delete logout_path

    post session_path, params: { provider: "general_user", email: "username+work@example.com", password: "supersecret" }
    expect(response).to redirect_to(mainpage_path)
  end
end
