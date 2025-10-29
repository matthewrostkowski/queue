require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with display_name and auth_provider" do
    u = User.new(display_name: "Guest", auth_provider: "guest")
    expect(u).to be_valid
  end

  it "is invalid without display_name" do
    u = User.new(auth_provider: "guest")
    expect(u).not_to be_valid
    expect(u.errors[:display_name]).to be_present
  end

  it "is invalid without auth_provider" do
    u = User.new(display_name: "X")
    expect(u).not_to be_valid
    expect(u.errors[:auth_provider]).to be_present
  end
  it "allows guest without email/password" do
    u = User.new(auth_provider: "guest", display_name: "Guest X")
    expect(u).to be_valid
  end

  it "requires email/password for general_user" do
    u = User.new(auth_provider: "general_user", display_name: "X")
    expect(u).not_to be_valid
    u.email = "a@b.com"
    u.password = "12345678"
    u.password_confirmation = "12345678"
    expect(u).to be_valid
  end

  it "downcases email" do
    u = User.create!(auth_provider: "general_user", display_name: "X",
                     email: "HELLO@TEST.COM", password: "12345678", password_confirmation: "12345678")
    expect(u.reload.email).to eq("hello@test.com")
  end
end
