class AddColumnsToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :user_id, :bigint unless column_exists?(:votes, :user_id)
    add_column :votes, :queue_item_id, :bigint unless column_exists?(:votes, :queue_item_id)
    add_column :votes, :vote_type, :integer, null: false, default: 1 unless column_exists?(:votes, :vote_type)
    
    add_foreign_key :votes, :users unless foreign_key_exists?(:votes, :users)
    add_foreign_key :votes, :queue_items unless foreign_key_exists?(:votes, :queue_items)
    
    add_index :votes, [:user_id, :queue_item_id], unique: true unless index_exists?(:votes, [:user_id, :queue_item_id], unique: true)
    add_index :votes, :queue_item_id unless index_exists?(:votes, :queue_item_id)
  end
end

