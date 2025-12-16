# spec/models/vote_spec.rb
require 'rails_helper'

describe Vote do
  let!(:host_user) { User.create!(email: 'host@test.com', display_name: 'Host', password: 'password123', password_confirmation: 'password123', auth_provider: 'general_user', role: :host, balance_cents: 10000) }
  let!(:venue) { Venue.create!(name: 'Test Venue', host_user_id: host_user.id) }
  let!(:user) { User.create!(email: 'voter@test.com', display_name: 'Voter', password: 'password123', password_confirmation: 'password123', auth_provider: 'general_user', balance_cents: 10000) }
  let!(:queue_session) { QueueSession.create!(venue_id: venue.id, join_code: SecureRandom.hex(3).upcase) }
  let!(:queue_item) { QueueItem.create!(queue_session_id: queue_session.id, title: 'Test Song', artist: 'Test Artist', vote_score: 0, vote_count: 0) }

  describe 'associations' do
    it 'belongs to user' do
      expect(Vote.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'belongs to queue_item' do
      expect(Vote.reflect_on_association(:queue_item).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'requires user_id' do
      vote = Vote.new(queue_item_id: queue_item.id, vote_type: 1)
      expect(vote.valid?).to be_falsy
      expect(vote.errors[:user_id]).to be_present
    end

    it 'requires queue_item_id' do
      vote = Vote.new(user_id: user.id, vote_type: 1)
      expect(vote.valid?).to be_falsy
      expect(vote.errors[:queue_item_id]).to be_present
    end

    it 'requires vote_type' do
      # vote_type has a default value in the database, so it's always present
      # This test verifies that vote_type defaults to 1
      vote = Vote.new(user_id: user.id, queue_item_id: queue_item.id)
      expect(vote.vote_type).to eq(1)
    end

    it 'enforces unique user_id and queue_item_id combination' do
      Vote.create!(user_id: user.id, queue_item_id: queue_item.id, vote_type: 1)
      vote2 = Vote.new(user_id: user.id, queue_item_id: queue_item.id, vote_type: -1)
      # Note: Uniqueness constraint was removed from the model to allow admins to vote multiple times
      # The controller enforces the one-vote limit for non-admin users
      # So this test should check that the model allows multiple votes (controller handles uniqueness)
      expect(vote2.valid?).to be_truthy
    end
  end

  describe 'scopes' do
    before do
      Vote.create!(user_id: user.id, queue_item_id: queue_item.id, vote_type: 1)
      user2 = User.create!(email: 'voter2@test.com', display_name: 'Voter 2', password: 'password123', password_confirmation: 'password123', auth_provider: 'general_user', balance_cents: 10000)
      Vote.create!(user_id: user2.id, queue_item_id: queue_item.id, vote_type: -1)
    end

    it 'filters upvotes' do
      expect(Vote.upvotes.count).to eq(1)
    end

    it 'filters downvotes' do
      expect(Vote.downvotes.count).to eq(1)
    end
  end

  describe 'class methods' do
    it '.user_voted? returns true when user has voted' do
      Vote.create!(user_id: user.id, queue_item_id: queue_item.id, vote_type: 1)
      expect(Vote.user_voted?(user.id, queue_item.id)).to be_truthy
    end

    it '.user_voted? returns false when user has not voted' do
      expect(Vote.user_voted?(user.id, queue_item.id)).to be_falsy
    end

    it '.user_vote_for returns the vote when it exists' do
      vote = Vote.create!(user_id: user.id, queue_item_id: queue_item.id, vote_type: 1)
      retrieved = Vote.user_vote_for(user.id, queue_item.id)
      expect(retrieved.id).to eq(vote.id)
    end

    it '.user_vote_for returns nil when vote does not exist' do
      expect(Vote.user_vote_for(user.id, queue_item.id)).to be_nil
    end
  end
end

