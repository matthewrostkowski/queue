class DynamicPricingService
  class << self
    # Main method to calculate price for a specific position
    def calculate_position_price(queue_session, desired_position)
      return 0 unless queue_session

      venue = queue_session.venue
      return 0 unless venue&.pricing_enabled

      # Get base price from venue settings
      base_price_cents = venue.base_price_cents || 100

      # Calculate multiplier based on all factors
      multiplier = calculate_base_multiplier(queue_session, desired_position)

      # Log detailed pricing breakdown
      Rails.logger.info "=" * 80
      Rails.logger.info "PRICING CALCULATION for Position #{desired_position}"
      Rails.logger.info "=" * 80
      Rails.logger.info "Base Price: #{base_price_cents} cents ($#{base_price_cents / 100.0})"
      Rails.logger.info "Active Users: #{get_active_user_count(queue_session)}"
      Rails.logger.info "Queue Velocity: #{get_queue_velocity(queue_session).round(2)} songs/min"
      Rails.logger.info "Queue Length: #{get_queue_length(queue_session)}"
      Rails.logger.info "-" * 80

      # Calculate final price
      price_cents = (base_price_cents * multiplier).round

      Rails.logger.info "Final Multiplier: #{multiplier.round(4)}"
      Rails.logger.info "FINAL PRICE: #{price_cents} cents ($#{price_cents / 100.0})"
      Rails.logger.info "=" * 80

      # Apply venue-specific settings (min/max prices, etc.)
      apply_venue_settings(price_cents, venue)
    end

    # Calculate the base multiplier from demand factors
    def calculate_base_multiplier(queue_session, desired_position)
      multiplier = 1.0

      # Factor 1: Active users (competition factor)
      # Increased user activity should drive up prices
      active_users = get_active_user_count(queue_session)
      user_multiplier = 1.0
      if active_users > 0
        # 3% per user, capped at 2x total
        user_multiplier = 1.0 + (active_users * 0.03)
        user_multiplier = [user_multiplier, 2.0].min
        multiplier *= user_multiplier
      end

      # Factor 2: Queue velocity (demand factor)
      # Recent additions indicate high demand
      velocity = get_queue_velocity(queue_session) # songs per minute
      velocity_multiplier = 1.0
      if velocity > 0
        # 5% per song/minute, capped at 1.5x total
        velocity_multiplier = 1.0 + (velocity * 0.05)
        velocity_multiplier = [velocity_multiplier, 1.5].min
        multiplier *= velocity_multiplier
      end

      # Factor 3: Position in queue (priority 3)
      # Position matters - earlier positions cost more
      if desired_position && desired_position > 0
        # Increased bonus: pos 1 = 3x, pos 2 = 2x, pos 5 = 1.4x, pos 10 = 1.2x
        position_bonus = 2.0 / desired_position
        position_factor = 1.0 + position_bonus
        multiplier *= position_factor
      end

      # Factor 4: Time of day (venue-specific peak hours)
      time_factor = time_of_day_factor(queue_session.venue)
      multiplier *= time_factor

      # Hard cap at 10x to prevent excessive pricing
      multiplier = [multiplier, 10.0].min

      # Log the breakdown
      Rails.logger.info "  User multiplier: #{user_multiplier.round(4)} (#{active_users} active users)"
      Rails.logger.info "  Velocity multiplier: #{velocity_multiplier.round(4)} (#{velocity.round(2)} songs/min)"
      Rails.logger.info "  Position multiplier: #{position_factor.round(4) if desired_position} (position #{desired_position})"
      Rails.logger.info "  Time factor: #{time_factor.round(4)}"

      multiplier
    end

    # Get factors for debugging/display
    def get_pricing_factors(queue_session, desired_position)
      venue = queue_session&.venue
      active_users = get_active_user_count(queue_session)
      queue_velocity = get_queue_velocity(queue_session)
      queue_length = get_queue_length(queue_session)
      base_price_cents = venue&.base_price_cents || 100

      factors = {
        active_users: active_users,
        queue_velocity: queue_velocity,
        queue_length: queue_length,
        base_price_cents: base_price_cents,
        venue_multiplier: venue&.price_multiplier || 1.0,
        time_factor: time_of_day_factor(venue)
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

    private

    # Count active users in the session (users who have added songs recently)
    def get_active_user_count(queue_session)
      return 0 unless queue_session

      # Count unique users who added songs in the last 30 minutes
      recent_threshold = 30.minutes.ago
      QueueItem.where(queue_session: queue_session)
               .where('created_at >= ?', recent_threshold)
               .distinct
               .count(:user_id)
    end

    # Calculate songs added per minute over recent period
    def get_queue_velocity(queue_session)
      return 0.0 unless queue_session

      # Look at last 10 minutes of activity
      time_window = 10.minutes.ago

      recent_additions = QueueItem.where(queue_session: queue_session)
                                  .where('created_at >= ?', time_window)
                                  .count

      # Convert to songs per minute (10 minutes window)
      recent_additions / 10.0
    end

    # Get current queue length
    def get_queue_length(queue_session)
      return 0 unless queue_session

      QueueItem.where(queue_session: queue_session, status: 'pending').count
    end

    # Calculate time-of-day multiplier based on venue peak hours
    def time_of_day_factor(venue)
      return 1.0 unless venue&.peak_hours_start && venue&.peak_hours_end

      current_hour = Time.current.hour
      peak_start = venue.peak_hours_start
      peak_end = venue.peak_hours_end

      # Handle cases where peak hours wrap around midnight
      if peak_start <= peak_end
        # Normal case (e.g., 18-22)
        in_peak = current_hour >= peak_start && current_hour < peak_end
      else
        # Wrap around midnight (e.g., 22-2)
        in_peak = current_hour >= peak_start || current_hour < peak_end
      end

      in_peak ? venue.peak_hours_multiplier || 1.5 : 1.0
    end

    # Apply venue-specific price constraints
    def apply_venue_settings(price_cents, venue)
      return price_cents unless venue

      # Apply venue multiplier
      price_cents = (price_cents * (venue.price_multiplier || 1.0)).round

      # Apply min/max constraints
      if venue.min_price_cents && price_cents < venue.min_price_cents
        price_cents = venue.min_price_cents
      end

      if venue.max_price_cents && price_cents > venue.max_price_cents
        price_cents = venue.max_price_cents
      end

      price_cents
    end
  end
end
