class AddPreviewUrlToQueueItems < ActiveRecord::Migration[7.0]
  def change
    add_column :queue_items, :preview_url, :string unless column_exists?(:queue_items, :preview_url)
  end
end