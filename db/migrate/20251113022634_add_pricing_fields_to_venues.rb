class AddPricingFieldsToVenues < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:venues, :pricing_enabled)
      add_column :venues, :pricing_enabled, :boolean, default: true, null: false
    end

    unless column_exists?(:venues, :base_price_cents)
      add_column :venues, :base_price_cents, :integer, default: 100, null: false
    end

    unless column_exists?(:venues, :price_multiplier)
      add_column :venues, :price_multiplier, :decimal, precision: 3, scale: 2, default: 1.0, null: false
    end

    unless column_exists?(:venues, :min_price_cents)
      add_column :venues, :min_price_cents, :integer, default: 50
    end

    unless column_exists?(:venues, :max_price_cents)
      add_column :venues, :max_price_cents, :integer, default: 1000
    end

    unless column_exists?(:venues, :peak_hours_start)
      add_column :venues, :peak_hours_start, :integer, default: 18 # 6 PM
    end

    unless column_exists?(:venues, :peak_hours_end)
      add_column :venues, :peak_hours_end, :integer, default: 22   # 10 PM
    end

    unless column_exists?(:venues, :peak_hours_multiplier)
      add_column :venues, :peak_hours_multiplier, :decimal, precision: 3, scale: 2, default: 1.5, null: false
    end
  end
end
