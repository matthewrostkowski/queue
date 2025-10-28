class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :display_name, null: false
      t.string :auth_provider, null: false
      t.string :access_token
      t.timestamps
    end
  end
end
