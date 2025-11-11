class QueueSession < ApplicationRecord
  belongs_to :venue

  has_many :queue_items,
           class_name: "QueueItem",
           foreign_key: :queue_session_id,
           dependent: :destroy

  has_many :songs, through: :queue_items
  has_many :users, through: :queue_items

  belongs_to :currently_playing_track, class_name: "QueueItem", foreign_key: :currently_playing_id, optional: true

  scope :active, -> { where(is_active: true) }

  validates :venue, presence: true

  before_create :generate_access_code
  validates :access_code, uniqueness: true, allow_nil: true

  # Get the queue in priority order
  def ordered_queue
    queue_items
      .where(played_at: nil)
      .includes(:song, :user)
      .sort_by { |qi| -qi.score }
  end

  # Get the next track to play
  def next_track
    ordered_queue.first
  end

  # Start playing a specific track
  def play_track!(queue_item)
    transaction do
      # Mark previous track as not playing
      queue_items.update_all(is_currently_playing: false)
      
      # Mark new track as playing
      queue_item.update!(
        is_currently_playing: true,
        played_at: Time.current
      )
      
      update!(
        currently_playing_id: queue_item.id,
        is_playing: true,
        playback_started_at: Time.current
      )
    end
  end

  # Stop playback
  def stop_playback!
    transaction do
      queue_items.update_all(is_currently_playing: false)
      update!(
        currently_playing_id: nil,
        is_playing: false,
        playback_started_at: nil
      )
    end
  end

  # Play next track in queue
  def play_next!
    next_up = next_track
    if next_up
      play_track!(next_up)
      next_up
    else
      stop_playback!
      nil
    end
  end

  private
  
  def generate_access_code
    loop do
      # Generate 6-digit code
      self.access_code = SecureRandom.random_number(999999).to_s.rjust(6, '0')
      # Break if code is unique
      break unless QueueSession.exists?(access_code: access_code)
    end
  end
end