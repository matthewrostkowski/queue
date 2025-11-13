class AddLastActivityToQueueSessions < ActiveRecord::Migration[8.0]
  def change
    # Track last activity time for queue sessions to calculate active users
    add_column :queue_sessions, :last_activity_at, :datetime
    add_index :queue_sessions, :last_activity_at
  end
end