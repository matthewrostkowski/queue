class QueueItem < ApplicationRecord
  belongs_to :queue_session
  belongs_to :song
  belongs_to :user

  # Validations - using actual database column names
  validates :base_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending playing played] }
  
  # Scopes - use vote_score for sorting (matches the frontend)
  scope :unplayed, -> { where(status: 'pending') }
  scope :played, -> { where(status: 'played') }
  scope :by_votes, -> { order(vote_score: :desc, created_at: :asc) }
  
  # Delegate song attributes for convenience
  delegate :title, :artist, :cover_url, :duration_ms, :preview_url, :spotify_id, to: :song, allow_nil: true
  
  # Helper method to work with dollars
  def base_price
    base_price_cents / 100.0
  end
  
  def base_price=(dollars)
    self.base_price_cents = (dollars.to_f * 100).to_i
  end
end