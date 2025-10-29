class CreateSongs < ActiveRecord::Migration[7.1]
  def change
    create_table :songs do |t|
      t.string :title, null: false
      t.string :artist, null: false
      t.string :spotify_id
      t.string :cover_url
      t.timestamps
    end
  end
end