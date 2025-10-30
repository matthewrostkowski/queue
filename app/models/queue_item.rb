class QueueItem < ApplicationRecord
  belongs_to :queue_session
  belongs_to :song, optional: true  # Make optional
  belongs_to :user, optional: true  # Make optional

  # Validations
  validates :title, presence: true
  validates :artist, presence: true
  
  # We're storing song data directly on QueueItem:
  # - title
  # - artist
  # - cover_url
  # - duration_ms
  # - preview_url
  # - spotify_id (Deezer ID)
  # - user_display_name (instead of user_id)
  # - vote_score
  
  # Scopes
  scope :unplayed, -> { where(played_at: nil) }
  scope :played, -> { where.not(played_at: nil) }
  scope :by_votes, -> { order(vote_score: :desc, created_at: :asc) }
end