require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let!(:admin) do
    User.create!(display_name: "Admin", email: "admin@example.com", password: "password", auth_provider: "general_user", role: :admin)
  end
  let!(:user1) do
    User.create!(display_name: "Alpha", email: "alpha@example.com", password: "password", auth_provider: "general_user", role: :user)
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "GET /admin/users" do
    it "renders the list and hides self actions" do
      get admin_users_path
      expect(response).to have_http_status(:ok)

      # shows table headers
      %w[ID Auth Provider Name Role Email Created Actions].each do |h|
        expect(response.body).to include(h)
      end

      # shows both users
      expect(response.body).to include(admin.email)
      expect(response.body).to include(user1.email)

      # self row should not have action links text (we print '(no self-actions)')
      expect(response.body).to include("(no self-actions)")
    end

    it "blocks non-admin users" do
      u = User.create!(display_name: "U", email: "u@example.com", password: "password", auth_provider: "local", role: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(u)

      get admin_users_path
      expect(response).to redirect_to(mainpage_path)
    end
  end

  describe "PATCH member actions" do
    it "shows '(no self-actions)' for the admin's own row and does not render any action buttons" do
        get admin_users_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(admin.email)
  # Confirm it shows "(no self-actions)" for that row
        expect(response.body).to include("(no self-actions)")
  # Ensure no action links for the admin's own record
        expect(response.body).not_to include(promote_to_admin_admin_user_path(admin))
        expect(response.body).not_to include(promote_to_host_admin_user_path(admin))
        expect(response.body).not_to include(demote_admin_user_path(admin))
end


    it "promotes another user to admin" do
      patch promote_to_admin_admin_user_path(user1)
      expect(response).to redirect_to(admin_users_path)
      expect(user1.reload.role).to eq("admin")
    end

    it "promotes another user to host and can demote" do
      patch promote_to_host_admin_user_path(user1)
      expect(user1.reload.role).to eq("host")

      patch demote_admin_user_path(user1)
      expect(user1.reload.role).to eq("user")
    end
  end
end
