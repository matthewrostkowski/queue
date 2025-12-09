class AllowAdminMultipleVotes < ActiveRecord::Migration[8.0]
  def change
    # Remove the unique index to allow admins to vote multiple times
    remove_index :votes, [:user_id, :queue_item_id], if_exists: true
    
    # Create a conditional unique index that only applies to non-admin users
    # We'll handle admin voting logic in the controller instead
    # For now, we just remove the constraint entirely since we're checking admin status in the controller
  end
end

