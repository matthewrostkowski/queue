require 'rails_helper'

RSpec.describe Venue, type: :model do
  let(:host) do
    User.create!(
      display_name: 'Test Host',
      auth_provider: 'general_user',
      email: 'host@test.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  describe 'associations' do
    it 'has many queue_sessions' do
      association = Venue.reflect_on_association(:queue_sessions)
      expect(association.macro).to eq(:has_many)
    end

    it 'belongs to host_user' do
      association = Venue.reflect_on_association(:host_user)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:class_name]).to eq('User')
      # Handle both string and symbol for foreign_key
      fk = association.options[:foreign_key]
      expect([fk, fk.to_s]).to include('host_user_id')
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      venue = Venue.new(host_user_id: host.id, venue_code: '123456')
      expect(venue).not_to be_valid
      expect(venue.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of host_user_id' do
      venue = Venue.new(name: 'Test Venue', venue_code: '123456')
      expect(venue).not_to be_valid
      expect(venue.errors[:host_user_id]).to include("can't be blank")
    end

    it 'validates presence of venue_code on update' do
      venue = Venue.create!(name: 'Test Venue', host_user_id: host.id)
      venue.venue_code = nil
      expect(venue).not_to be_valid
      expect(venue.errors[:venue_code]).to include("can't be blank")
    end

    it 'validates uniqueness of venue_code' do
      Venue.create!(name: 'Existing Venue', host_user_id: host.id, venue_code: '123456')
      venue = Venue.new(name: 'New Venue', host_user_id: host.id, venue_code: '123456')
      expect(venue).not_to be_valid
      expect(venue.errors[:venue_code]).to include("has already been taken")
    end

    it 'validates format of venue_code (must be 6 digits)' do
      venue = Venue.new(name: 'Test Venue', host_user_id: host.id)
      
      # Too short
      venue.venue_code = '12345'
      expect(venue).not_to be_valid
      expect(venue.errors[:venue_code]).to include("must be 6 digits")
      
      # Too long
      venue.venue_code = '1234567'
      expect(venue).not_to be_valid
      expect(venue.errors[:venue_code]).to include("must be 6 digits")
      
      # Non-numeric
      venue.venue_code = 'ABC123'
      expect(venue).not_to be_valid
      expect(venue.errors[:venue_code]).to include("must be 6 digits")
      
      # Valid
      venue.venue_code = '123456'
      expect(venue).to be_valid
    end

    it 'is valid with name, host_user_id, and venue_code' do
      venue = Venue.new(name: 'Test Venue', host_user_id: host.id, venue_code: '123456')
      expect(venue).to be_valid
    end
  end

  describe 'creation' do
    it 'can be created with all attributes' do
      venue = Venue.create!(
        name: 'Test Venue',
        location: '123 Test St',
        capacity: 100,
        host_user_id: host.id
      )
      expect(venue.name).to eq('Test Venue')
      expect(venue.location).to eq('123 Test St')
      expect(venue.capacity).to eq(100)
      expect(venue.host_user_id).to eq(host.id)
    end

    it 'automatically generates a venue code on creation' do
      venue = Venue.create!(
        name: 'Test Venue',
        host_user_id: host.id
      )
      expect(venue.venue_code).to be_present
      expect(venue.venue_code).to match(/^\d{6}$/)
    end

    it 'uses provided venue code if given' do
      venue = Venue.create!(
        name: 'Test Venue',
        host_user_id: host.id,
        venue_code: '999999'
      )
      expect(venue.venue_code).to eq('999999')
    end

    it 'generates unique venue codes' do
      venue1 = Venue.create!(name: 'Venue 1', host_user_id: host.id)
      venue2 = Venue.create!(name: 'Venue 2', host_user_id: host.id)
      expect(venue1.venue_code).not_to eq(venue2.venue_code)
    end
  end

  describe '#active_session' do
    let(:venue) do
      Venue.create!(
        name: 'Test Venue',
        location: 'NYC',
        capacity: 200,
        host_user_id: host.id
      )
    end

    it 'returns the active queue session' do
      active_session = venue.queue_sessions.create!(
        status: 'active',
        started_at: Time.current,
        join_code: '123456'
      )
      expect(venue.active_session).to eq(active_session)
    end

    it 'returns nil if no active session' do
      expect(venue.active_session).to be_nil
    end

    it 'returns first active session when multiple exist' do
      paused = venue.queue_sessions.create!(
        status: 'paused',
        started_at: Time.current,
        join_code: '111111'
      )
      active = venue.queue_sessions.create!(
        status: 'active',
        started_at: Time.current,
        join_code: '222222'
      )
      expect(venue.active_session).to eq(active)
      expect(venue.active_session).not_to eq(paused)
    end

    it 'ignores ended sessions' do
      ended = venue.queue_sessions.create!(
        status: 'ended',
        started_at: Time.current,
        ended_at: Time.current,
        join_code: '333333'
      )
      expect(venue.active_session).to be_nil
    end
  end

  describe 'queue_sessions relationship' do
    let(:venue) do
      Venue.create!(
        name: 'Test Venue',
        location: 'Brooklyn',
        capacity: 150,
        host_user_id: host.id
      )
    end

    it 'can have multiple queue sessions' do
      session1 = venue.queue_sessions.create!(
        status: 'ended',
        started_at: 1.day.ago,
        ended_at: 1.day.ago + 2.hours,
        join_code: '111111'
      )
      session2 = venue.queue_sessions.create!(
        status: 'active',
        started_at: Time.current,
        join_code: '222222'
      )
      
      expect(venue.queue_sessions.count).to eq(2)
      expect(venue.queue_sessions).to include(session1, session2)
    end

    it 'destroys associated queue_sessions when venue is deleted' do
      session = venue.queue_sessions.create!(
        status: 'active',
        started_at: Time.current,
        join_code: '123456'
      )
      
      venue.destroy
      expect(QueueSession.find_by(id: session.id)).to be_nil
    end
  end

  describe 'venue code methods' do
    let(:venue) do
      Venue.create!(
        name: 'Test Venue',
        host_user_id: host.id
      )
    end

    describe '#generate_venue_code' do
      it 'generates a new venue code' do
        old_code = venue.venue_code
        venue.generate_venue_code
        expect(venue.venue_code).not_to eq(old_code)
        expect(venue.venue_code).to match(/^\d{6}$/)
      end
    end

    describe '#regenerate_venue_code' do
      it 'regenerates venue code and saves it' do
        old_code = venue.venue_code
        result = venue.regenerate_venue_code
        
        expect(result).to be true
        expect(venue.reload.venue_code).not_to eq(old_code)
        expect(venue.venue_code).to match(/^\d{6}$/)
      end

      it 'returns false if save fails' do
        # Make venue invalid by removing required field
        allow(venue).to receive(:save).and_return(false)
        result = venue.regenerate_venue_code
        expect(result).to be false
      end
    end

    describe '.find_by_venue_code' do
      it 'finds venue by its code' do
        found_venue = Venue.find_by_venue_code(venue.venue_code)
        expect(found_venue).to eq(venue)
      end

      it 'returns nil for non-existent code' do
        found_venue = Venue.find_by_venue_code('000000')
        expect(found_venue).to be_nil
      end

      it 'returns nil for invalid format' do
        found_venue = Venue.find_by_venue_code('ABC123')
        expect(found_venue).to be_nil
      end

      it 'returns nil for nil input' do
        found_venue = Venue.find_by_venue_code(nil)
        expect(found_venue).to be_nil
      end
    end
  end

  describe 'scopes' do
    before do
      Venue.create!(name: 'Venue 1', host_user_id: host.id)
      other_host = User.create!(
        display_name: 'Other Host',
        auth_provider: 'general_user',
        email: 'other@test.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      Venue.create!(name: 'Venue 2', host_user_id: other_host.id)
    end

    it 'finds venues by name' do
      venue = Venue.find_by(name: 'Venue 1')
      expect(venue.host_user_id).to eq(host.id)
    end

    it 'finds venues by host_user_id' do
      venues = Venue.where(host_user_id: host.id)
      expect(venues.count).to eq(1)
      expect(venues.first.name).to eq('Venue 1')
    end
  end
end