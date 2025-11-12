module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.count
      @total_venues = Venue.count
      @active_sessions = QueueSession.where(is_active: true).count
      @total_songs = Song.count
    end
  end
end