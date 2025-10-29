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
end
