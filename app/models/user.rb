# app/models/user.rb
class User < ApplicationRecord
  # =====================
  # Associations
  # =====================
  has_many :queue_items, dependent: :nullify
  has_many :queued_songs, through: :queue_items, source: :song

  # =====================
  # Authentication
  # =====================
  has_secure_password validations: false

  # =====================
  # Validations
  # =====================
  validates :display_name, presence: true
  validates :auth_provider, presence: true
  
  validates :email,
            format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
            uniqueness: { case_sensitive: false, allow_blank: true }
  
  # For general_user provider, require email and password
  validates :email, presence: true, if: -> { auth_provider == 'general_user' }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { auth_provider == 'general_user' && new_record? }

  # =====================
  # Methods
  # =====================
  
  def total_upvotes_received
    queue_items.sum(:vote_count)
  end
  
  def queue_summary
    {
      username: display_name,
      songs_queued: queue_items.count,
      total_upvotes: total_upvotes_received
    }
  end

  # =====================
  # Callbacks
  # =====================
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
