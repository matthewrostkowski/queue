class UsersController < ApplicationController
  before_action :require_user!

  def summary
    user = User.find(params[:id])
    render json: user.queue_summary
  end
end
