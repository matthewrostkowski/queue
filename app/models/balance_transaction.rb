class BalanceTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :queue_item, optional: true
  
  validates :amount_cents, presence: true
  validates :transaction_type, presence: true, inclusion: { in: %w[credit debit refund initial] }
  validates :balance_after_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :credits, -> { where(transaction_type: %w[credit refund initial]) }
  scope :debits, -> { where(transaction_type: 'debit') }
  scope :recent, -> { order(created_at: :desc) }
  
  def credit?
    transaction_type.in?(%w[credit refund initial])
  end
  
  def debit?
    transaction_type == 'debit'
  end
  
  def amount_display
    "$#{'%.2f' % (amount_cents.abs / 100.0)}"
  end
end
