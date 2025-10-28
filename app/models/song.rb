class Song < ApplicationRecord
  has_many :queue_items
  validates :title, :artist, presence: true
end
