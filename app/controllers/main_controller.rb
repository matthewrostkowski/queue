class MainController < ApplicationController
  before_action :authenticate_user!
  def index
    @sessions = QueueSession
      .active
      .includes(:venue, :queue_items, :currently_playing_track)
      .order(created_at: :desc)
  end
end
