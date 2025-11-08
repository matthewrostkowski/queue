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
  # We added email + password_digest via migrations in this branch.
  # Allow blank email for guest flows but normalize if present.
  has_secure_password validations: false

  # =====================
  # Validations
  # =====================
  validates :email,
            format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
            uniqueness: { case_sensitive: false, allow_blank: true }

  # =====================
  # Callbacks
  # =====================
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
