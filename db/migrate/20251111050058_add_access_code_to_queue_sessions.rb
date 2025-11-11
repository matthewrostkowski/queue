class AddAccessCodeToQueueSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :queue_sessions, :access_code, :string
    add_index :queue_sessions, :access_code, unique: true
  end
end
