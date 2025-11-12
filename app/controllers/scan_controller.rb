class ScanController < ApplicationController
  before_action :authenticate_user!
  def index
  
  end

  def create
    code = params[:code]&.strip
    
    if code.blank?
      flash[:alert] = "Please enter a code"
      redirect_to scan_path and return
    end
    
    # Find queue session by code
    queue_session = QueueSession.find_by(access_code: code, is_active: true)
    
    if queue_session
      # Redirect to that venue's queue
      redirect_to queue_path, #venue_queue_path(queue_session.venue_id), 
                  notice: "Joined #{queue_session.venue.name}!"
    else
      flash[:alert] = "Invalid or inactive code: #{code}"
      redirect_to scan_path
    end
  end
end
