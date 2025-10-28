class QueueSession < ApplicationRecord
  belongs_to :venue
  has_many :queue_items, dependent: :destroy

  scope :active, -> { where(is_active: true) }
end
