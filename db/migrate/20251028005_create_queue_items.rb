class CreateQueueItems < ActiveRecord::Migration[7.1]
  def change
    create_table :queue_items do |t|
      t.references :song, null: false, foreign_key: true
      t.references :queue_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :base_price, precision: 8, scale: 2, null: false
      t.integer :vote_count, default: 0, null: false
      t.integer :base_priority, default: 0, null: false
      t.string  :status, default: 'pending', null: false
      t.timestamps
    end
  end
end