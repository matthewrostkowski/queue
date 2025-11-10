class AddPricingAndVotingToQueueItems < ActiveRecord::Migration[7.1]
  def change
    # add_column will blow up if the column exists already
    unless column_exists?(:queue_items, :base_price_cents)
      add_column :queue_items, :base_price_cents, :integer, default: 100, null: false
    end

    unless column_exists?(:queue_items, :vote_count)
      add_column :queue_items, :vote_count, :integer, default: 0, null: false
    end

    unless column_exists?(:queue_items, :base_priority)
      add_column :queue_items, :base_priority, :integer, default: 0, null: false
    end
  end
end
