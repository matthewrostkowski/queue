class AddSongDetailsToQueueItems < ActiveRecord::Migration[7.0]
  def change
    add_column :queue_items, :title, :string
    add_column :queue_items, :artist, :string
    add_column :queue_items, :spotify_id, :string
  end
end
