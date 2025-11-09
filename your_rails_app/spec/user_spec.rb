require "rails_helper"

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has many queue_items' do
      association = User.reflect_on_association(:queue_items)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many queued_songs through queue_items' do
      association = User.reflect_on_association(:queued_songs)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:queue_items)
      expect(association.options[:source]).to eq(:song)
    end
  end

  describe 'validations' do
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

  describe '#total_upvotes_received' do
    let(:user) { User.create!(display_name: 'TestUser', auth_provider: 'guest') }
    let(:venue) { Venue.create!(name: 'Test Venue', location: '123 Test St', capacity: 200) }
    let(:session) { venue.queue_sessions.create!(is_active: true) }

    context 'when user has no queue items' do
      it 'returns 0' do
        expect(user.total_upvotes_received).to eq(0)
      end
    end

    context 'when user has queue items with votes' do
      before do
        song1 = Song.create!(title: 'Song 1', artist: 'Artist 1')
        song2 = Song.create!(title: 'Song 2', artist: 'Artist 2')
        
        QueueItem.create!(
          user: user,
          song: song1,
          queue_session: session,
          base_price: 3.99,
          vote_count: 5
        )
        
        QueueItem.create!(
          user: user,
          song: song2,
          queue_session: session,
          base_price: 4.99,
          vote_count: 10
        )
      end

      it 'returns sum of all vote counts' do
        expect(user.total_upvotes_received).to eq(15)
      end
    end

    context 'when user has queue items with zero votes' do
      before do
        song = Song.create!(title: 'Song', artist: 'Artist')
        QueueItem.create!(
          user: user,
          song: song,
          queue_session: session,
          base_price: 3.99,
          vote_count: 0
        )
      end

      it 'returns 0' do
        expect(user.total_upvotes_received).to eq(0)
      end
    end
  end

  describe '#queue_summary' do
    let(:user) { User.create!(display_name: 'TestUser', auth_provider: 'guest') }

    it 'returns hash with username, songs count, and upvotes' do
      summary = user.queue_summary

      expect(summary).to be_a(Hash)
      expect(summary[:username]).to eq('TestUser')
      expect(summary[:queued_count]).to eq(0)
      expect(summary[:upvotes_total]).to eq(0)
    end

    context 'with queue items' do
      before do
        venue = Venue.create!(name: 'Test', location: '123 St', capacity: 200)
        session = venue.queue_sessions.create!(is_active: true)
        song = Song.create!(title: 'Test', artist: 'Artist')
        
        QueueItem.create!(
          user: user,
          song: song,
          queue_session: session,
          base_price: 3.99,
          vote_count: 7
        )
      end

      it 'returns correct counts' do
        summary = user.queue_summary

        expect(summary[:queued_count]).to eq(1)
        expect(summary[:upvotes_total]).to eq(7)
      end
    end
  end
end
