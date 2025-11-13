require 'rails_helper'

RSpec.feature "Dynamic Pricing", type: :feature do
  let!(:venue) { create(:venue, :with_pricing_enabled, name: "Test Club") }
  let!(:queue_session) { create(:queue_session, venue: venue, is_active: true) }
  let!(:user) { create(:user, display_name: "TestUser", role: :admin) }
  let!(:admin) { create(:user, display_name: "AdminUser", role: :admin) }
  
  before do
    # Create some initial queue activity
    5.times do |i|
      create(:queue_item, 
        queue_session: queue_session,
        user: create(:user),
        created_at: i.minutes.ago
      )
    end
  end
  
  # scenario "User sees dynamic prices on search page" do
  #   login_as(user)
  #   visit search_path
    
  #   fill_in "q", with: "jazz"
  #   click_button "Search"
    
  #   expect(page).to have_css(".position-price")
  #   # Price should be displayed and not be $0.00
  #   price_text = find(".position-price", match: :first).text
  #   expect(price_text.to_f).to be > 0
  # end
  
  scenario "Admin can configure venue pricing settings" do
    login_as(admin)
    visit admin_venues_path
    
    click_link "Edit"
    
    # Update pricing settings
    fill_in "venue_base_price_cents", with: "500"
    fill_in "venue_price_multiplier", with: "2.0"
    fill_in "venue_peak_hours_start", with: "18"
    fill_in "venue_peak_hours_end", with: "22"
    fill_in "venue_peak_hours_multiplier", with: "2.0"
    
    click_button "Save Pricing Settings"
    
    expect(page).to have_content("Pricing settings updated successfully")
    
    # Verify changes were saved
    venue.reload
    expect(venue.base_price_cents).to eq(500)
    expect(venue.price_multiplier).to eq(2.0)
  end
  
  scenario "Prices increase with demand" do
    # Simulate low demand
    low_demand_price = DynamicPricingService.calculate_position_price(queue_session, 1)
    
    # Add more users to simulate high demand
    10.times do
      create(:queue_item, 
        queue_session: queue_session,
        user: create(:user),
        created_at: 30.seconds.ago
      )
    end
    
    high_demand_price = DynamicPricingService.calculate_position_price(queue_session, 1)
    
    expect(high_demand_price).to be > low_demand_price
  end
  
  scenario "Position selection shows different prices" do
    login_as(user)
    visit search_path
    
    fill_in "q", with: "music"
    click_button "Search"
    
    # Click queue button to see position options
    #find(".queue-btn", match: :first).click
    click_button "+ Queue"
    
    # Should show position selection dialog (simplified for test)
    # In real app, this would be a modal
    expect(page.driver.browser.switch_to.alert.text).to include("Next Up")
    expect(page.driver.browser.switch_to.alert.text).to include("Skip 1 Song")
    expect(page.driver.browser.switch_to.alert.text).to include("Skip 2 Songs")
    
    page.driver.browser.switch_to.alert.dismiss
  end
  
  scenario "User gets refund when bumped down" do
    # User pays for position 1
    item1 = create(:queue_item,
      queue_session: queue_session,
      user: user,
      position_paid_cents: 1000,
      position_guaranteed: 1,
      inserted_at_position: 1,
      base_priority: 0
    )
    
    # Another user outbids for position 1
    new_user = create(:user)
    item2 = create(:queue_item,
      queue_session: queue_session,
      user: new_user
    )
    
    QueuePositionService.insert_at_position(item2, 1, 2000)
    
    # Original user should have received a refund
    item1.reload
    expect(item1.refund_amount_cents).to be > 0
    expect(item1.current_position_in_queue).to eq(2)
  end
end
