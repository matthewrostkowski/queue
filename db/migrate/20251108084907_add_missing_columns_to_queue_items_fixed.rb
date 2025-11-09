class AddMissingColumnsToQueueItemsFixed < ActiveRecord::Migration[7.1]
  def change
    # Add vote_score for ordering
    add_column :queue_items, :vote_score, :integer, default: 0, null: false unless column_exists?(:queue_items, :vote_score)
    
    # Add title, artist, preview_url for direct queue item creation
    add_column :queue_items, :title, :string unless column_exists?(:queue_items, :title)
    add_column :queue_items, :artist, :string unless column_exists?(:queue_items, :artist)
    add_column :queue_items, :preview_url, :string unless column_exists?(:queue_items, :preview_url)
    
    # Rename base_price to base_price_cents and change to integer
    if column_exists?(:queue_items, :base_price) && !column_exists?(:queue_items, :base_price_cents)
      # Convert existing decimal values to cents (multiply by 100)
      # Then rename column
      rename_column :queue_items, :base_price, :base_price_cents
      change_column :queue_items, :base_price_cents, :integer, null: false
    elsif !column_exists?(:queue_items, :base_price_cents)
      add_column :queue_items, :base_price_cents, :integer, null: false, default: 0
    end
  end
end
