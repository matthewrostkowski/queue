# app/models/user.rb
class User < ApplicationRecord
  enum :role, { user: 0, host: 1, admin: 2 }
  # =====================
  # Associations
  # =====================
  has_many :queue_items, dependent: :nullify
  has_many :queued_songs, through: :queue_items, source: :song
  has_many :balance_transactions, dependent: :destroy

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
  # =====================
  # Balance Management
  # =====================
  
  def balance
    balance_cents / 100.0
  end
  
  def balance_display
    "$#{'%.2f' % balance}"
  end
  
  def has_sufficient_balance?(amount_cents)
    balance_cents >= amount_cents
  end
  
  # Deduct amount from balance (for queue payments)
  def debit_balance!(amount_cents, description: nil, queue_item: nil)
    raise "Insufficient balance" unless has_sufficient_balance?(amount_cents)
    
    transaction do
      # Update user balance
      new_balance = balance_cents - amount_cents
      update!(balance_cents: new_balance)
      
      # Record transaction
      balance_transactions.create!(
        amount_cents: -amount_cents,
        transaction_type: 'debit',
        description: description || "Queue payment",
        queue_item: queue_item,
        balance_after_cents: new_balance
      )
    end
  end
  
  # Add amount to balance (for refunds or credits)
  def credit_balance!(amount_cents, description: nil, queue_item: nil)
    transaction do
      # Update user balance
      new_balance = balance_cents + amount_cents
      update!(balance_cents: new_balance)
      
      # Record transaction
      balance_transactions.create!(
        amount_cents: amount_cents,
        transaction_type: 'refund',
        description: description || "Queue refund",
        queue_item: queue_item,
        balance_after_cents: new_balance
      )
    end
  end
  
  # Initialize balance for new users
  def initialize_balance!
    return if balance_transactions.exists?
    
    transaction do
      balance_transactions.create!(
        amount_cents: 10000,
        transaction_type: 'initial',
        description: "Welcome bonus",
        balance_after_cents: balance_cents
      )
    end
  end

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
