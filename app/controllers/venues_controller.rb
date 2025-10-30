class VenuesController < ApplicationController
  def show
    venue = Venue.find(params[:id])
    queue_session = venue.queue_sessions.active.first
    render json: {
      venue: { id: venue.id, name: venue.name, location: venue.location, capacity: venue.capacity },
      queue_session: queue_session.present? ? { id: queue_session.id, is_active: queue_session.is_active } : nil
    }
  end
end
