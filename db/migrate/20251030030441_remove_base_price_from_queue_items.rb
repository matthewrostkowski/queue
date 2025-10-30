class RemoveBasePriceFromQueueItems < ActiveRecord::Migration[8.0]
  def change
    remove_column :queue_items, :base_price, :decimal
  end
end
