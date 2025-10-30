class AddPlaybackToQueue < ActiveRecord::Migration[7.0]
  def change
    add_column :queue_sessions, :currently_playing_id, :integer
    add_column :queue_sessions, :is_playing, :boolean, default: false
    add_column :queue_sessions, :playback_started_at, :datetime
    
    add_column :queue_items, :played_at, :datetime
    add_column :queue_items, :is_currently_playing, :boolean, default: false
    
    add_index :queue_sessions, :currently_playing_id
    add_index :queue_items, :played_at
  end
end