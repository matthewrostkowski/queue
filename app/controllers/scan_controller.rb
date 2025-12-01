# app/controllers/scan_controller.rb
class ScanController < ApplicationController
  def index
    @error = nil
  end

  # POST /join or /scan - User enters a join code
  def join_by_code
    code = params[:join_code].to_s.strip.presence || params[:code].to_s.strip

    # Validate format (both venue codes and session codes are 6 digits)
    unless VenueCodeGenerator.valid_format?(code)
      @error = "Invalid code format. Please enter a 6-digit code."
      return render :index
    end

    # Try to find venue by venue code first
    venue = VenueCodeGenerator.find_by_code(code)
    if venue
      # Found a venue by its venue code
      active_session = venue.active_queue_session
      
      if active_session
        # Join the venue's active session
        set_current_queue_session(active_session)
        redirect_to queue_path, notice: "Welcome to #{venue.name}! 🎵"
      else
        # Venue exists but has no active session
        @error = "#{venue.name} is not currently accepting song requests. Please check back later."
        render :index
      end
    else
      # Not a venue code, try session code
      session_record = JoinCodeGenerator.find_active_session(code)
      if session_record
        # Found an active session by session code
        set_current_queue_session(session_record)
        redirect_to queue_path, notice: "Welcome to #{session_record.venue.name}! 🎵"
      else
        # Code not found anywhere
        @error = "Code not found or session is no longer active. Please try again."
        render :index
      end
    end
  rescue => e
    Rails.logger.error("Error joining queue: #{e.message}")
    @error = "An error occurred. Please try again."
    render :index
  end

  # Backwards compatibility if anything calls ScanController#create
  alias_method :create, :join_by_code
end
