class AddMissingColumnsToQueueItems < ActiveRecord::Migration[7.0]
  def change
    add_column :queue_items, :cover_url, :string
    add_column :queue_items, :duration_ms, :integer
    add_column :queue_items, :user_display_name, :string
    add_column :queue_items, :vote_score, :integer, default: 0
  end
end
