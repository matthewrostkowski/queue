class Venue < ApplicationRecord
  has_many :queue_sessions,
           class_name: "QueueSession",
           foreign_key: :venue_id,
           dependent: :destroy

  validates :name, presence: true

  # returns the active queue session for this venue
  def active_queue_session
    queue_sessions.find_by(is_active: true)
  end
end
