class VenuesController < ApplicationController
  before_action :require_user!

  def show
    venue = Venue.find(params[:id])
    queue_session = venue.queue_sessions.active.first
    render json: {
      venue: { id: venue.id, name: venue.name, address: venue.address },
      queue_session: queue_session.present? ? { id: queue_session.id, is_active: queue_session.is_active } : nil
    }
  end
end
