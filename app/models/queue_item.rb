class QueueItem < ApplicationRecord
  belongs_to :queue_session
  belongs_to :song, optional: true
  belongs_to :user

  # Validations
  validates :base_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending playing played] }
  
  # Validate that we have either a song OR direct title/artist
  validate :must_have_song_or_title_artist
  
  # Scopes
  scope :unplayed, -> { where(status: 'pending') }
  scope :played, -> { where(status: 'played') }
  scope :by_votes, -> { order(vote_score: :desc, created_at: :asc) }
  
  # Override attribute readers to check both song and direct attributes
  def title
    read_attribute(:title) || song&.title
  end
  
  def artist
    read_attribute(:artist) || song&.artist
  end
  
  def preview_url
    read_attribute(:preview_url) || song&.preview_url
  end
  
  def cover_url
    song&.cover_url
  end
  
  def duration_ms
    song&.duration_ms
  end
  
  def spotify_id
    song&.spotify_id
  end
  
  # Helper method to work with dollars
  def base_price
    base_price_cents / 100.0
  end
  
  def base_price=(dollars)
    self.base_price_cents = (dollars.to_f * 100).to_i
  end
  
  private
  
  def must_have_song_or_title_artist
    if song_id.blank? && (read_attribute(:title).blank? || read_attribute(:artist).blank?)
      errors.add(:base, "Must have either a song or title/artist")
    end
  end
end
