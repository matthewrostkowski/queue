class AddVenueCodeToVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :venues, :venue_code, :string
    add_index :venues, :venue_code, unique: true
  end
end
