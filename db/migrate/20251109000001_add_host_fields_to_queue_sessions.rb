class AddHostFieldsToQueueSessions < ActiveRecord::Migration[7.0]
  def change
    # Add columns, allowing null initially
    add_column :queue_sessions, :join_code, :string unless column_exists?(:queue_sessions, :join_code)
    add_column :queue_sessions, :status, :string, default: 'active' unless column_exists?(:queue_sessions, :status)
    add_column :queue_sessions, :started_at, :datetime unless column_exists?(:queue_sessions, :started_at)
    add_column :queue_sessions, :ended_at, :datetime unless column_exists?(:queue_sessions, :ended_at)
    add_column :queue_sessions, :code_expires_at, :datetime unless column_exists?(:queue_sessions, :code_expires_at)

    # Populate existing records
    reversible do |dir|
      dir.up do
        # Set status based on is_active for existing records
        execute <<-SQL
          UPDATE queue_sessions
          SET status = CASE WHEN is_active = 1 THEN 'active' ELSE 'ended' END
          WHERE status IS NULL
        SQL

        # Generate join codes for existing records
        QueueSession.reset_column_information
        QueueSession.where(join_code: nil).find_each do |session|
          session.update_column(:join_code, SecureRandom.hex(3).upcase)
        end

        # Set started_at for existing records
        execute <<-SQL
          UPDATE queue_sessions
          SET started_at = created_at
          WHERE started_at IS NULL
        SQL
      end
    end

    # Now make join_code NOT NULL
    change_column_null :queue_sessions, :join_code, false
    change_column_null :queue_sessions, :status, false

    add_index :queue_sessions, :join_code unless index_exists?(:queue_sessions, :join_code)
    add_index :queue_sessions, [:venue_id, :status] unless index_exists?(:queue_sessions, [:venue_id, :status])
  end
end