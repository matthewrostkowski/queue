# app/services/dynamic_pricing_service.rb
class DynamicPricingService
  class << self
    # Main method to calculate price for a specific position
    def calculate_position_price(queue_session, desired_position)
      return 0 unless queue_session
      
      venue = queue_session.venue
      return 0 unless venue&.pricing_enabled
      
      # Get base price from venue settings
      base_price = venue.base_price_cents || 100
      
      # Calculate multiplier based on all factors
      multiplier = calculate_base_multiplier(queue_session, desired_position)
      
      # Apply venue multiplier
      multiplier *= venue.price_multiplier if venue.price_multiplier
      
      # Apply time of day factor
      multiplier *= time_of_day_factor(venue)
      
      # Cap multiplier at 10x to prevent extreme prices
      multiplier = [multiplier, 10.0].min
      
      # Calculate final price
      price = (base_price * multiplier).round
      
      # Apply venue min/max caps
      apply_venue_settings(price, venue)
    end
    
    # Calculate the base multiplier from demand factors
    def calculate_base_multiplier(queue_session, desired_position)
      multiplier = 1.0
      
      # Factor 1: Active users (priority 1)
      # Very modest increase - competition should matter but not dominate
      active_users = get_active_user_count(queue_session)
      if active_users > 1
        # 3% increase per user above 1, capped at 2x
        user_multiplier = 1 + (active_users - 1) * 0.03
        multiplier *= [user_multiplier, 2.0].min
      end
      
      # Factor 2: Queue velocity (priority 2)
      # Minimal surge pricing
      velocity = get_queue_velocity(queue_session)
      if velocity > 0
        # 5% increase per song/minute, capped at 1.5x
        velocity_multiplier = 1 + velocity * 0.05
        multiplier *= [velocity_multiplier, 1.5].min
      end
      
      # Factor 3: Position in queue (priority 3)
      # Very gentle position curve - position 1 is at most 2x position 10
      if desired_position > 0
        # Linear decrease: pos 1 = 1.5x, pos 5 = 1.1x, pos 10 = 1.05x
        position_bonus = 0.5 / desired_position
        position_factor = 1.0 + position_bonus
        multiplier *= position_factor
      end
      
      multiplier
    end
    
    # Count unique active users in the last 5 minutes
    def get_active_user_count(queue_session)
      return 0 unless queue_session
      
      five_minutes_ago = Time.current - 5.minutes
      
      # Count users who added songs in last 5 minutes
      queue_session.queue_items
                   .where('created_at > ?', five_minutes_ago)
                   .select(:user_id)
                   .distinct
                   .count
    end
    
    # Calculate songs added per minute in last 10 minutes
    def get_queue_velocity(queue_session)
      return 0.0 unless queue_session
      
      ten_minutes_ago = Time.current - 10.minutes
      
      # Count songs added in last 10 minutes
      songs_count = queue_session.queue_items
                                 .where('created_at > ?', ten_minutes_ago)
                                 .count
      
      # Return songs per minute
      songs_count / 10.0
    end
    
    # Apply time of day factor based on venue peak hours
    def time_of_day_factor(venue)
      current_hour = Time.current.hour
      
      # Check if within peak hours
      if venue.peak_hours_start && venue.peak_hours_end
        if venue.peak_hours_start <= venue.peak_hours_end
          # Normal case: e.g., 19 to 23 (7pm to 11pm)
          if current_hour >= venue.peak_hours_start && current_hour < venue.peak_hours_end
            return venue.peak_hours_multiplier || 1.5
          end
        else
          # Wraps around midnight: e.g., 22 to 2 (10pm to 2am)
          if current_hour >= venue.peak_hours_start || current_hour < venue.peak_hours_end
            return venue.peak_hours_multiplier || 1.5
          end
        end
      end
      
      1.0  # No peak hour multiplier
    end
    
    # Apply venue min/max price settings
    def apply_venue_settings(price, venue)
      # Apply minimum price
      if venue.min_price_cents && price < venue.min_price_cents
        price = venue.min_price_cents
      end
      
      # Apply maximum price
      if venue.max_price_cents && price > venue.max_price_cents
        price = venue.max_price_cents
      end
      
      price
    end
    
    # Helper method to get pricing factors for display/debugging
    def get_pricing_factors(queue_session, desired_position = nil)
      return {} unless queue_session
      
      venue = queue_session.venue
      active_users = get_active_user_count(queue_session)
      velocity = get_queue_velocity(queue_session)
      queue_length = queue_session.songs_count
      
      factors = {
        active_users: active_users,
        queue_velocity: velocity.round(2),
        queue_length: queue_length,
        time_factor: time_of_day_factor(venue),
        venue_multiplier: venue&.price_multiplier || 1.0,
        base_price_cents: venue&.base_price_cents || 100
      }
      
      if desired_position
        factors[:desired_position] = desired_position
        if desired_position > 0
          position_factor = 1.0 / (desired_position ** 0.5)
          if queue_length > 0
            position_factor *= (1 + Math.log(queue_length + 1) * 0.2)
          end
          factors[:position_factor] = position_factor
        else
          factors[:position_factor] = 1.0
        end
      end
      
      factors
    end
  end
end
