class AddPricingToVenues < ActiveRecord::Migration[8.0]
  def change
    # Pricing settings for venues
    add_column :venues, :pricing_enabled, :boolean, default: true, null: false
    add_column :venues, :base_price_cents, :integer, default: 100, null: false
    add_column :venues, :min_price_cents, :integer, default: 1, null: false
    add_column :venues, :max_price_cents, :integer, default: 50000, null: false # $500 max
    add_column :venues, :price_multiplier, :decimal, precision: 10, scale: 2, default: 1.0, null: false
    
    # Peak hours configuration
    add_column :venues, :peak_hours_start, :integer, default: 19, null: false # 7pm
    add_column :venues, :peak_hours_end, :integer, default: 23, null: false # 11pm
    add_column :venues, :peak_hours_multiplier, :decimal, precision: 10, scale: 2, default: 1.5, null: false
  end
end