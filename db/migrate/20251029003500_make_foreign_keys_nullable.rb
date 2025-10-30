class MakeForeignKeysNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :queue_items, :song_id, true
    change_column_null :queue_items, :user_id, true
  end
end
