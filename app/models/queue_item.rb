class QueueItem < ApplicationRecord
  belongs_to :song
  belongs_to :queue_session
  belongs_to :user

  validates :song, :queue_session, :user, presence: true
  validates :base_price_cents, presence: true, numericality: { greater_than: 0 }

  def price_for_display
    demand = QueueItem.where(queue_session_id: queue_session_id, song_id: song_id, status: 'pending').count
    multiplier = 1.0 + (demand - 1) * 0.10 + (vote_count * 0.05)
    base_price = base_price_cents / 100.0
    (base_price * multiplier).round(2)
  end

  def vote!(delta)
    self.vote_count = [0, vote_count + delta].max
    save!
  end
end
