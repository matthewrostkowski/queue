class ProfilesController < ApplicationController
  before_action :require_user!

  def show
    @user = current_user
    
    @queue_items = @user.queue_items
                        .includes(:song, :queue_session)
                        .order(created_at: :desc)
                        .limit(20)
    
    @summary = @user.queue_summary
  end
end
