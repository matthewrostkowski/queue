require 'rails_helper'

RSpec.describe QueueItem, type: :model do
  let(:user) { User.create!(display_name: "TestUser", auth_provider: "guest") }
  let(:host) { User.create!(display_name: "Host", auth_provider: "guest") }
  let(:venue) { Venue.create!(name: "Test Venue", host_user_id: host.id) }
  let(:session) { venue.queue_sessions.create!(status: 'active', started_at: Time.current, join_code: '123456') }
  let(:song) { Song.create!(title: "Song Title", artist: "Artist Name") }

  describe 'validations' do
    it 'is valid with title and artist' do
      item = QueueItem.new(user: user, song: song, queue_session: session, base_price: 3.99)
      expect(item).to be_valid
    end
  end

  describe 'ordering' do
    it 'orders by vote_score desc then created_at asc' do
      song2 = Song.create!(title: "Another Song", artist: "Another Artist")
      item1 = QueueItem.create!(user: user, song: song, queue_session: session, base_price: 3.99, vote_count: 5)
      item2 = QueueItem.create!(user: user, song: song2, queue_session: session, base_price: 3.99, vote_count: 10)
      ordered = QueueItem.all.sort_by { |i| [-i.vote_count, i.created_at] }
      expect(ordered.first.id).to eq(item2.id)
      expect(ordered.last.id).to eq(item1.id)
    end
  end
end
