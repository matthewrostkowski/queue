class AddBalanceToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add balance column to track user credits
    add_column :users, :balance_cents, :integer, default: 10000, null: false # $100.00 starting balance
    
    # Add index for performance when checking balances
    add_index :users, :balance_cents
    
    # Track transaction history (optional but recommended)
    create_table :balance_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :transaction_type, null: false # 'credit', 'debit', 'refund'
      t.string :description
      t.references :queue_item, foreign_key: true # Link to queue item if applicable
      t.integer :balance_after_cents, null: false
      t.timestamps
    end
    
    add_index :balance_transactions, [:user_id, :created_at]
  end
end