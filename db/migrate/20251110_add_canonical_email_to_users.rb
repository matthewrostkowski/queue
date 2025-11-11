class AddCanonicalEmailToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :canonical_email, :string
    add_index  :users, :canonical_email, unique: true, where: "canonical_email IS NOT NULL", name: "index_users_on_canonical_email_unique"
  end
end