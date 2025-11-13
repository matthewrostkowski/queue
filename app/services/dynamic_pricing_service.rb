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
      multiplier_before_venue = multiplier
      
      # Apply venue multiplier
      if venue.price_multiplier
        multiplier *= venue.price_multiplier
      end
      multiplier_after_venue = multiplier
      
      # Apply time of day factor
      time_factor = time_of_day_factor(venue)
      multiplier *= time_factor
      multiplier_after_time = multiplier
      
      # Cap multiplier at 10x to prevent extreme prices
      multiplier_before_cap = multiplier
      multiplier = [multiplier, 10.0].min
      
      # Calculate final price
      price = (base_price * multiplier).round
      
      # Log detailed pricing breakdown
      Rails.logger.info "=" * 80
      Rails.logger.info "PRICING CALCULATION for Position #{desired_position}"
      Rails.logger.info "=" * 80
      Rails.logger.info "Base Price: #{base_price} cents ($#{base_price / 100.0})"
      Rails.logger.info "Active Users: #{get_active_user_count(queue_session)}"
      Rails.logger.info "Queue Velocity: #{get_queue_velocity(queue_session).round(2)} songs/min"
      Rails.logger.info "Queue Length: #{queue_session.songs_count}"
      Rails.logger.info "-" * 80
      Rails.logger.info "Multiplier after base factors: #{multiplier_before_venue.round(4)}"
      Rails.logger.info "Venue multiplier: #{venue.price_multiplier || 1.0}"
      Rails.logger.info "Multiplier after venue: #{multiplier_after_venue.round(4)}"
      Rails.logger.info "Time of day factor: #{time_factor.round(4)}"
      Rails.logger.info "Multiplier after time: #{multiplier_after_time.round(4)}"
      Rails.logger.info "Multiplier before cap: #{multiplier_before_cap.round(4)}"
      Rails.logger.info "Multiplier after 10x cap: #{multiplier.round(4)}"
      Rails.logger.info "-" * 80
      Rails.logger.info "FINAL PRICE: #{price} cents ($#{price / 100.0})"
      Rails.logger.info "=" * 80
      
      # Apply venue min/max caps
      apply_venue_settings(price, venue)
    end
    
    # Calculate the base multiplier from demand factors
    def calculate_base_multiplier(queue_session, desired_position)
      multiplier = 1.0
      
      # Factor 1: Active users (priority 1)
      # Very modest increase - competition should matter but not dominate
      active_users = get_active_user_count(queue_session)
      user_multiplier = 1.0
      if active_users > 1
        # 3% increase per user above 1, capped at 2x
        user_multiplier = 1 + (active_users - 1) * 0.03
        user_multiplier = [user_multiplier, 2.0].min
        multiplier *= user_multiplier
      end
      
      # Factor 2: Queue velocity (priority 2)
      # Minimal surge pricing
      velocity = get_queue_velocity(queue_session)
      velocity_multiplier = 1.0
      if velocity > 0
        # 5% increase per song/minute, capped at 1.5x
        velocity_multiplier = 1 + velocity * 0.05
        velocity_multiplier = [velocity_multiplier, 1.5].min
        multiplier *= velocity_multiplier
      end
      
      # Factor 3: Position in queue (priority 3)
      # Position matters - earlier positions cost more
      position_factor = 1.0
      if desired_position > 0
        # Increased bonus: pos 1 = 3x, pos 2 = 2x, pos 5 = 1.4x, pos 10 = 1.2x
        position_bonus = 2.0 / desired_position
        position_factor = 1.0 + position_bonus
        multiplier *= position_factor
      end
      
      # Log the breakdown
      Rails.logger.info "  User multiplier: #{user_multiplier.round(4)} (#{active_users} active users)"
      Rails.logger.info "  Velocity multiplier: #{velocity_multiplier.round(4)} (#{velocity.round(2)} songs/min)"
      Rails.logger.info "  Position multiplier: #{position_factor.round(4)} (position #{desired_position})"
      
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
          # Use the SAME formula as calculate_base_multiplier
          position_bonus = 2.0 / desired_position
          position_factor = 1.0 + position_bonus
          factors[:position_factor] = position_factor
        else
          factors[:position_factor] = 1.0
        end
      end
      
      factors
    end
  end
end
