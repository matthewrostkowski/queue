class AddLocationAndCapacityToVenues < ActiveRecord::Migration[8.0]
  def change
    # Rename address to location to match original intention
    rename_column :venues, :address, :location
    # Add missing capacity field
    add_column :venues, :capacity, :integer
  end
end
