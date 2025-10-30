class User < ApplicationRecord
  has_many :queue_items, dependent: :nullify
  has_many :queued_songs, through: :queue_items, source: :song

  # ── Providers ───────────────────────────────────────────────
  has_secure_password validations: false 

  # ── Validations ─────────────────────────────────────────────
  validates :auth_provider, presence: true
  validates :display_name, presence: true

  with_options if: -> { auth_provider == "general_user" } do
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }
    validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
  end

  # ── Callbacks ───────────────────────────────────────────────
  before_save :downcase_email

  def total_upvotes_received
    queue_items.sum(:vote_count)
  end

  def queue_summary
    {
      id: id,
      username: display_name,
      queued_count: queue_items.count,
      upvotes_total: total_upvotes_received,
      by_status: queue_items.group(:status).count
    }
  end

  private

  def downcase_email
    self.email = email.to_s.downcase.presence
  end

  def password_required?
    auth_provider == "general_user" && (password_digest.blank? || password.present?)
  end
end
