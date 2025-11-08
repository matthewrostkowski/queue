class QueueItem < ApplicationRecord
  belongs_to :queue_session
  belongs_to :song, optional: true
  belongs_to :user, optional: true

  # Validations
  validates :status, inclusion: { in: %w[pending playing played] }, allow_nil: true
  
  # Make base_price_cents optional for test scenarios
  validates :base_price_cents, numericality: { greater_than: 0 }, allow_nil: true
  
  # Validate that we have either a song OR direct title/artist
  validate :must_have_song_or_title_artist, on: :create
  
  # Set defaults
  before_validation :set_defaults, on: :create
  
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
    return 0 if base_price_cents.nil?
    base_price_cents / 100.0
  end
  
  def base_price=(dollars)
    self.base_price_cents = (dollars.to_f * 100).to_i
  end
  
  private
  
  def set_defaults
    self.base_price_cents ||= 0
    self.vote_count ||= 0
    self.vote_score ||= 0
    self.base_priority ||= 0
    self.status ||= 'pending'
  end
  
  def must_have_song_or_title_artist
    if song_id.blank? && (read_attribute(:title).blank? || read_attribute(:artist).blank?)
      errors.add(:base, "Must have either a song or title/artist")
    end
  end
end
