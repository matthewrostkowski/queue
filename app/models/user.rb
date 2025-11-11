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

  validates :canonical_email,
            uniqueness: { case_sensitive: false, allow_blank: true }
  # For general_user provider, require email and password
  validates :email, presence: true,
            if: -> { auth_provider == 'general_user' }

  validates :password, presence: true, length: { minimum: 8 },
            if: -> { auth_provider == 'general_user' && (new_record? || password.present?) }

  # =====================
  # Methods
  # =====================
  
  before_validation :normalize_and_canonicalize_email

  def total_upvotes_received
    queue_items.sum(:vote_count)
  end
  
  def queue_summary
    {
      username: display_name,
      queued_count: queue_items.count,
      upvotes_total: total_upvotes_received
    }
  end

  # =====================
  # Callbacks
  # =====================
  private

  def normalize_and_canonicalize_email
    self.email = email.to_s.strip.downcase.presence
    self.canonical_email = canonicalize_email(email) if email.present?
  end

  def canonicalize_email(raw)
    return nil if raw.blank?
    email = raw.to_s.strip.downcase
    local, domain = email.split("@", 2)
    return email unless local && domain

    local = local.split("+", 2)[0]
    local = local.delete(".")
    "#{local}@#{domain}"
  end
end
