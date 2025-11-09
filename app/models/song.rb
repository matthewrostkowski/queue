class Song < ApplicationRecord
  has_many :queue_items
  validates :title, :artist, presence: true

  has_many :users_who_queued, through: :queue_items, source: :user

  def album_art
    cover_url.presence || "https://via.placeholder.com/200x200/1DB954/ffffff?text=#{title[0]}"
  end
end
