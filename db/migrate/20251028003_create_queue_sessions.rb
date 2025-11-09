class CreateQueueSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :queue_sessions do |t|
      t.references :venue, null: false, foreign_key: true
      t.boolean :is_active, default: true, null: false
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    add_index :queue_sessions, [:venue_id, :is_active]
  end
end