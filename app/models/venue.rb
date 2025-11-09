class Venue < ApplicationRecord
  has_many :queue_sessions, dependent: :destroy

  validates :name, presence: true
end
