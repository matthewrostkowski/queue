class CreateQueueSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :queue_sessions do |t|
      t.references :venue, null: false, foreign_key: true
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end
  end
end