class UsersController < ApplicationController
  # GET /users/:id/summary
  def summary
    user = User.find(params[:id])
    counts = user.queue_items.group(:status).count
    upvotes = user.queue_items.sum(:vote_count)
    render json: {
      id: user.id, name: user.display_name,
      queued_count: user.queue_items.count, upvotes_total: upvotes,
      by_status: counts
    }
  end
end
