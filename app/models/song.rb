class Song < ApplicationRecord
<<<<<<< HEAD
  has_many :queue_items
  validates :title, :artist, presence: true

  has_many :users_who_queued, through: :queue_items, source: :user

  def album_art
    cover_url.presence || "https://via.placeholder.com/200x200/1DB954/ffffff?text=#{title[0]}"
=======
  has_many :queue_items, dependent: :destroy
  has_many :queue_sessions, through: :queue_items
  has_many :users, through: :queue_items

  validates :title,  presence: true
  validates :artist, presence: true

  def duration_formatted
    return nil unless duration_ms
    total_seconds = duration_ms / 1000
    minutes = total_seconds / 60
    seconds = total_seconds % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  def display_name
    "#{title} – #{artist}"
>>>>>>> 5cb46b8 (Song search and playing Queue screen)
  end
end
