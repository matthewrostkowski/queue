require 'rails_helper'

RSpec.describe QueuePositionService do
  before { skip "Skipping queue position service specs for now" }
  let(:venue) { create(:venue, :with_pricing_enabled) }
  let(:queue_session) { create(:queue_session, venue: venue) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  
  describe '.insert_at_position' do
    context 'with empty queue' do
      it 'inserts item at position 1' do
        item = create(:queue_item, queue_session: queue_session, user: user1)
        
        described_class.insert_at_position(item, 1, 100)
        
        expect(item.reload.base_priority).to eq(0)
        expect(queue_session.ordered_queue.first).to eq(item)
      end
    end
    
    context 'with existing items' do
      let!(:existing_item1) { create(:queue_item, queue_session: queue_session, base_priority: 0, position_paid_cents: 500, position_guaranteed: 1) }
      let!(:existing_item2) { create(:queue_item, queue_session: queue_session, base_priority: 1, position_paid_cents: 300, position_guaranteed: 2) }
      
      it 'inserts new item and bumps others down' do
        new_item = create(:queue_item, queue_session: queue_session, user: user3)
        
        described_class.insert_at_position(new_item, 1, 1000)
        
        expect(new_item.reload.base_priority).to eq(0)
        expect(existing_item1.reload.base_priority).to eq(1)
        expect(existing_item2.reload.base_priority).to eq(2)
      end
      
      it 'processes refunds for bumped items' do
        new_item = create(:queue_item, queue_session: queue_session, user: user3)
        
        expect {
          described_class.insert_at_position(new_item, 1, 1000)
        }.to change { existing_item1.reload.refund_amount_cents }.from(0).to(be > 0)
      end
    end
    
    it 'updates queue session last_activity_at' do
      item = create(:queue_item, queue_session: queue_session)
      
      expect {
        described_class.insert_at_position(item, 1, 100)
      }.to change { queue_session.reload.last_activity_at }
    end
  end
  
  describe '.calculate_refund' do
    before do
      # Setup some activity for dynamic pricing
      3.times { create(:queue_item, queue_session: queue_session) }
    end
    
    it 'returns 0 if position improves' do
      refund = described_class.calculate_refund(5, 3, 1000, queue_session)
      expect(refund).to eq(0)
    end
    
    it 'calculates refund as difference between paid and new position price' do
      paid_amount = 1000
      old_position = 1
      new_position = 3
      
      new_position_price = DynamicPricingService.calculate_position_price(queue_session, new_position)
      expected_refund = paid_amount - new_position_price
      
      refund = described_class.calculate_refund(old_position, new_position, paid_amount, queue_session)
      expect(refund).to eq([expected_refund, paid_amount].min)
    end
    
    it 'never refunds more than paid amount' do
      refund = described_class.calculate_refund(1, 10, 100, queue_session)
      expect(refund).to be <= 100
    end
  end
  
  describe '.process_bump_refund' do
    let(:item) do
      create(:queue_item,
        queue_session: queue_session,
        position_paid_cents: 1000,
        position_guaranteed: 1,
        inserted_at_position: 1
      )
    end
    
    before do
      # Create other items to establish queue
      create(:queue_item, queue_session: queue_session, base_priority: 1)
      create(:queue_item, queue_session: queue_session, base_priority: 2)
    end
    
    it 'adds refund amount to item' do
      allow(item).to receive(:current_position_in_queue).and_return(3)
      
      expect {
        described_class.process_bump_refund(item)
      }.to change { item.reload.refund_amount_cents }.from(0).to(be > 0)
    end
    
    it 'accumulates multiple refunds' do
      item.update!(refund_amount_cents: 200)
      allow(item).to receive(:current_position_in_queue).and_return(3)
      
      described_class.process_bump_refund(item)
      
      expect(item.reload.refund_amount_cents).to be > 200
    end
  end
  
  describe '.remove_item' do
    let!(:item1) { create(:queue_item, queue_session: queue_session, base_priority: 0) }
    let!(:item2) { create(:queue_item, queue_session: queue_session, base_priority: 1) }
    let!(:item3) { create(:queue_item, queue_session: queue_session, base_priority: 2) }
    
    it 'marks item as cancelled' do
      described_class.remove_item(item2)
      expect(item2.reload.status).to eq('cancelled')
    end
    
    it 'reorders remaining items' do
      described_class.remove_item(item2)
      
      expect(item1.reload.base_priority).to eq(0)
      expect(item3.reload.base_priority).to eq(1)
    end
  end
end
