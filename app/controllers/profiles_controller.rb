class ProfilesController < ApplicationController
  before_action :require_user!  # 未登入就擋掉

  def show
    @user = current_user
    
    # Get queue items for display
    @queue_items = @user.queue_items
                        .includes(:song, :queue_session)
                        .order(created_at: :desc)
                        .limit(20)
    
    # Summary stats
    @summary = {
      username: @user.display_name,
      songs_queued_count: @user.queue_items.count,
      total_upvotes_received: @user.queue_items.sum(:vote_count)
    }
  end
end
