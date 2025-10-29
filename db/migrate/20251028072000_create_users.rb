class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :display_name, null: false
      t.string :auth_provider, null: false, default: "guest"
      t.string :access_token

      t.timestamps
    end
    add_index :users, :auth_provider
  end
end
