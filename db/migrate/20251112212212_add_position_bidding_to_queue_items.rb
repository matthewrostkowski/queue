class AddPositionBiddingToQueueItems < ActiveRecord::Migration[8.0]
  def change
    # Position bidding columns for queue_items
    add_column :queue_items, :position_paid_cents, :integer
    add_column :queue_items, :position_guaranteed, :integer
    add_column :queue_items, :refund_amount_cents, :integer, default: 0, null: false
    add_column :queue_items, :inserted_at_position, :integer
    
    # Add index for better query performance
    add_index :queue_items, :position_guaranteed
  end
end