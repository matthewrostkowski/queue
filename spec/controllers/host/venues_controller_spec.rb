require 'rails_helper'

RSpec.describe Host::VenuesController, type: :controller do
  let(:host_user) do
    User.create!(
      display_name: 'Host User',
      auth_provider: 'general_user',
      email: 'host@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      role: 'host'
    )
  end

  let(:regular_user) do
    User.create!(
      display_name: 'Regular User',
      auth_provider: 'general_user',
      email: 'user@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      role: 'user'
    )
  end

  let(:venue) do
    Venue.create!(
      name: 'Test Venue',
      host_user_id: host_user.id
    )
  end

  describe 'POST #create' do
    before { sign_in host_user }

    it 'creates venue with auto-generated venue code' do
      expect {
        post :create, params: {
          venue: {
            name: 'New Venue',
            location: '123 Test St',
            capacity: 100
          }
        }
      }.to change(Venue, :count).by(1)

      new_venue = Venue.last
      expect(new_venue.venue_code).to be_present
      expect(new_venue.venue_code).to match(/^\d{6}$/)
    end

    it 'creates venue with unique venue code' do
      # Create first venue
      post :create, params: {
        venue: { name: 'Venue 1' }
      }
      venue1 = Venue.last

      # Create second venue
      post :create, params: {
        venue: { name: 'Venue 2' }
      }
      venue2 = Venue.last

      expect(venue1.venue_code).not_to eq(venue2.venue_code)
    end
  end

  describe 'PATCH #regenerate_venue_code' do
    context 'when user is the host' do
      before { sign_in host_user }

      it 'regenerates venue code successfully' do
        old_code = venue.venue_code
        patch :regenerate_venue_code, params: { id: venue.id }

        venue.reload
        expect(venue.venue_code).not_to eq(old_code)
        expect(venue.venue_code).to match(/^\d{6}$/)
        expect(response).to redirect_to(host_venue_path(venue))
        expect(flash[:notice]).to eq("Venue code regenerated successfully")
      end

      it 'handles regeneration failure gracefully' do
        allow_any_instance_of(Venue).to receive(:regenerate_venue_code).and_return(false)

        patch :regenerate_venue_code, params: { id: venue.id }

        expect(response).to redirect_to(host_venue_path(venue))
        expect(flash[:alert]).to eq("Failed to regenerate venue code")
      end
    end

    context 'when user is not the host' do
      before { sign_in regular_user }

      it 'redirects with unauthorized message' do
        patch :regenerate_venue_code, params: { id: venue.id }

        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("permission")
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        patch :regenerate_venue_code, params: { id: venue.id }

        expect(response).to redirect_to(login_path)
      end
    end
  end

  # Helper methods for authentication
  def sign_in(user)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
  end
end
