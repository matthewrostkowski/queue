require 'rails_helper'

RSpec.describe DynamicPricingService do
  let(:venue) { create(:venue, :with_pricing_enabled) }
  let(:queue_session) { create(:queue_session, venue: venue) }
  
  describe '.calculate_position_price' do
    context 'when pricing is disabled' do
      before { venue.update!(pricing_enabled: false) }
      
      it 'returns 0' do
        expect(described_class.calculate_position_price(queue_session, 1)).to eq(0)
      end
    end
    
    context 'with single user (no competition)' do
      before do
        create(:queue_item, queue_session: queue_session, created_at: 1.minute.ago)
      end
      
      it 'returns minimum price (1 cent)' do
        price = described_class.calculate_position_price(queue_session, 1)
        expect(price).to eq(venue.min_price_cents)
      end
    end
    
    context 'with moderate demand (5 users, 10 songs)' do
      before do
        5.times do |i|
          user = create(:user)
          2.times do |j|
            create(:queue_item, 
              queue_session: queue_session, 
              user: user,
              created_at: (i * 2 + j).minutes.ago
            )
          end
        end
      end
      
      it 'calculates price with demand multiplier' do
        price = described_class.calculate_position_price(queue_session, 1)
        # Base price (100) * active users multiplier * position factor
        expect(price).to be > venue.base_price_cents
        expect(price).to be < 1000 # Reasonable upper bound
      end
      
      it 'charges more for earlier positions' do
        price_pos_1 = described_class.calculate_position_price(queue_session, 1)
        price_pos_5 = described_class.calculate_position_price(queue_session, 5)
        expect(price_pos_1).to be > price_pos_5
      end
    end
    
    context 'with high demand (25 users, 50 songs)' do
      before do
        25.times do |i|
          user = create(:user)
          2.times do |j|
            create(:queue_item, 
              queue_session: queue_session, 
              user: user,
              created_at: ((i * 2 + j) * 10).seconds.ago
            )
          end
        end
      end
      
      it 'triggers surge pricing' do
        price = described_class.calculate_position_price(queue_session, 1)
        expect(price).to be > 1000 # Surge pricing should kick in
      end
      
      it 'respects maximum price cap' do
        price = described_class.calculate_position_price(queue_session, 1)
        expect(price).to be <= venue.max_price_cents
      end
    end
    
    context 'during peak hours' do
      before do
        allow(Time).to receive(:current).and_return(Time.zone.parse("20:00")) # 8 PM
        venue.update!(
          peak_hours_start: 19,
          peak_hours_end: 23,
          peak_hours_multiplier: 2.0
        )
      end
      
      it 'applies peak hour multiplier' do
        create(:queue_item, queue_session: queue_session)
        create(:queue_item, queue_session: queue_session)
        
        regular_price = venue.base_price_cents * 1.3 # Basic multiplier
        peak_price = described_class.calculate_position_price(queue_session, 1)
        
        expect(peak_price).to be >= (regular_price * 2.0).round
      end
    end
  end
  
  describe '.get_active_user_count' do
    it 'counts unique users in last 5 minutes' do
      user1 = create(:user)
      user2 = create(:user)
      
      # Recent items
      create(:queue_item, queue_session: queue_session, user: user1, created_at: 1.minute.ago)
      create(:queue_item, queue_session: queue_session, user: user1, created_at: 2.minutes.ago)
      create(:queue_item, queue_session: queue_session, user: user2, created_at: 3.minutes.ago)
      
      # Old item (should not count)
      create(:queue_item, queue_session: queue_session, user: user1, created_at: 6.minutes.ago)
      
      expect(described_class.get_active_user_count(queue_session)).to eq(2)
    end
  end
  
  describe '.get_queue_velocity' do
    it 'calculates songs per minute over last 10 minutes' do
      # 5 songs in 10 minutes = 0.5 songs/minute
      5.times do |i|
        create(:queue_item, queue_session: queue_session, created_at: (i * 2).minutes.ago)
      end
      
      expect(described_class.get_queue_velocity(queue_session)).to eq(0.5)
    end
    
    it 'ignores songs older than 10 minutes' do
      create(:queue_item, queue_session: queue_session, created_at: 5.minutes.ago)
      create(:queue_item, queue_session: queue_session, created_at: 11.minutes.ago)
      
      expect(described_class.get_queue_velocity(queue_session)).to eq(0.1)
    end
  end
  
  describe '.time_of_day_factor' do
    context 'with normal peak hours (19-23)' do
      before do
        venue.update!(
          peak_hours_start: 19,
          peak_hours_end: 23,
          peak_hours_multiplier: 1.5
        )
      end
      
      it 'returns 1.0 during off-peak hours' do
        allow(Time).to receive(:current).and_return(Time.zone.parse("14:00"))
        expect(described_class.time_of_day_factor(venue)).to eq(1.0)
      end
      
      it 'returns peak multiplier during peak hours' do
        allow(Time).to receive(:current).and_return(Time.zone.parse("20:00"))
        expect(described_class.time_of_day_factor(venue)).to eq(1.5)
      end
    end
    
    context 'with overnight peak hours (22-2)' do
      before do
        venue.update!(
          peak_hours_start: 22,
          peak_hours_end: 2,
          peak_hours_multiplier: 2.0
        )
      end
      
      it 'handles midnight wraparound correctly' do
        allow(Time).to receive(:current).and_return(Time.zone.parse("23:30"))
        expect(described_class.time_of_day_factor(venue)).to eq(2.0)
        
        allow(Time).to receive(:current).and_return(Time.zone.parse("01:00"))
        expect(described_class.time_of_day_factor(venue)).to eq(2.0)
        
        allow(Time).to receive(:current).and_return(Time.zone.parse("03:00"))
        expect(described_class.time_of_day_factor(venue)).to eq(1.0)
      end
    end
  end
end
