class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_current_user
  helper_method :current_user

  private


  def set_current_user
    return if session[:user_id].blank?
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def current_user
    @current_user
  end

  def require_user!
    render json: { error: 'unauthorized' }, status: :unauthorized unless current_user
  end
end
