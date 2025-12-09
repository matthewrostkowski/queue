# app/models/vote.rb
class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :queue_item

  validates :user_id, uniqueness: { scope: :queue_item_id, message: "can only vote once per song in queue" }
  validates :user_id, :queue_item_id, :vote_type, presence: true

  # Scopes
  scope :upvotes, -> { where(vote_type: 1) }
  scope :downvotes, -> { where(vote_type: -1) }

  # Check if user has voted on this queue item
  def self.user_voted?(user_id, queue_item_id)
    exists?(user_id: user_id, queue_item_id: queue_item_id)
  end

  # Get user's vote on queue item
  def self.user_vote_for(user_id, queue_item_id)
    find_by(user_id: user_id, queue_item_id: queue_item_id)
  end
end

