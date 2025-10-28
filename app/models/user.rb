class User < ApplicationRecord
  has_many :queue_items, dependent: :nullify

  validates :display_name, presence: true
  validates :auth_provider, presence: true
end
