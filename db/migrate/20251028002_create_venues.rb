class CreateVenues < ActiveRecord::Migration[7.1]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.integer :capacity, null: false
      t.timestamps
    end
  end
end