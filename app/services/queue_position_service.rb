# app/services/queue_position_service.rb
class QueuePositionService
  class << self
    # Insert a queue item at a specific position, handling bumping and refunds
    def insert_at_position(queue_item, desired_position, paid_amount)
      return false unless queue_item && queue_item.queue_session
      
      queue_session = queue_item.queue_session
      
      # Lock the queue session to prevent concurrent modifications
      queue_session.with_lock do
        # Update last activity for the session
        queue_session.update!(last_activity_at: Time.current)
        
        # Get all unplayed items in current order
        ordered_items = queue_session.queue_items
                                     .where(played_at: nil)
                                     .where.not(id: queue_item.id)
                                     .order(:base_priority, :created_at)
                                     .to_a
        
        # Insert our item at the desired position (1-indexed)
        position_index = [desired_position - 1, 0].max
        ordered_items.insert(position_index, queue_item)
        
        # Process bumps and refunds for items that moved down
        process_position_changes(ordered_items, position_index, queue_session)
        
        # Update all items with new priorities
        update_priorities(ordered_items)
      end
      
      true
    end
    
    # Calculate refund when an item is bumped to a new position
    def calculate_refund(old_position, new_position, paid_amount, queue_session)
      return 0 if new_position <= old_position  # No refund if moving up or staying
      return 0 if paid_amount <= 0
      
      # Calculate the current market price for the new position
      new_position_price = DynamicPricingService.calculate_position_price(queue_session, new_position)
      
      # Refund = what they paid - what the new position costs
      refund = paid_amount - new_position_price
      
      # Never refund more than what was paid
      [refund, paid_amount].min
    end
    
    # Process refunds for bumped items
    def process_bump_refund(bumped_item)
      return unless bumped_item.position_paid_cents && bumped_item.position_paid_cents > 0
      
      old_position = bumped_item.position_guaranteed || bumped_item.inserted_at_position
      return unless old_position
      
      # Calculate new position
      new_position = bumped_item.current_position_in_queue
      
      # Calculate refund amount
      refund_amount = calculate_refund(
        old_position,
        new_position,
        bumped_item.position_paid_cents,
        bumped_item.queue_session
      )
      
      if refund_amount > 0
        # Add to cumulative refunds
        bumped_item.refund_amount_cents = (bumped_item.refund_amount_cents || 0) + refund_amount
        bumped_item.save!
        
        # Credit the user's balance
        if bumped_item.user
          bumped_item.user.credit_balance!(
            refund_amount,
            description: "Refund: Bumped from position #{old_position} to #{new_position}",
            queue_item: bumped_item
          )
        end
        
        Rails.logger.info "Refunded #{refund_amount} cents to user #{bumped_item.user_id} for queue item #{bumped_item.id}"
      end
    end
    
    # Remove an item and process refunds for items that move up
    def remove_item(queue_item)
      return unless queue_item
      
      queue_session = queue_item.queue_session
      return unless queue_session
      
      queue_session.with_lock do
        # Mark as removed/cancelled
        queue_item.update!(status: 'cancelled')
        
        # Get remaining items
        remaining_items = queue_session.queue_items
                                       .where(played_at: nil)
                                       .where(status: 'pending')
                                       .order(:base_priority, :created_at)
                                       .to_a
        
        # Update priorities for remaining items
        update_priorities(remaining_items)
      end
    end
    
    private
    
    # Process position changes and calculate refunds
    def process_position_changes(ordered_items, inserted_index, queue_session)
      # Items after the inserted position may need refunds
      ordered_items.each_with_index do |item, index|
        next if index <= inserted_index  # Only process items that were pushed down
        
        # Skip the newly inserted item
        next if item.position_guaranteed.nil? && item.position_paid_cents.nil?
        
        # If this item had a guaranteed position and paid for it
        if item.position_guaranteed && item.position_paid_cents && item.position_paid_cents > 0
          old_position = item.position_guaranteed
          new_position = index + 1  # Convert to 1-indexed
          
          # Only process if actually bumped down
          if new_position > old_position
            process_bump_refund(item)
          end
        end
      end
    end
    
    # Update base_priority for all items to maintain order
    def update_priorities(ordered_items)
      ordered_items.each_with_index do |item, index|
        # Use negative priority so lower numbers play first
        new_priority = index
        
        # Update if changed
        if item.base_priority != new_priority
          item.update_columns(
            base_priority: new_priority,
            updated_at: Time.current
          )
        end
      end
    end
  end
end
