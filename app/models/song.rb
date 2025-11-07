# app/models/song.rb
class Song < ApplicationRecord
  has_many :queue_items, dependent: :destroy
  has_many :queue_sessions, through: :queue_items
  has_many :users_who_queued, through: :queue_items, source: :user

  validates :title, :artist, presence: true

  def album_art
    cover_url.presence || "https://via.placeholder.com/200x200/1DB954/ffffff?text=#{title.to_s[0]}"
  end

  def duration_formatted
    return nil unless duration_ms.present?
    total_seconds = duration_ms.to_i / 1000
    minutes = total_seconds / 60
    seconds = total_seconds % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  def display_name
    "#{title} — #{artist}"
  end
end
