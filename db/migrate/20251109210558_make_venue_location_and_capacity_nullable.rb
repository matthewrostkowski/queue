class MakeVenueLocationAndCapacityNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :venues, :location, true
    change_column_null :venues, :capacity, true
  end
end
