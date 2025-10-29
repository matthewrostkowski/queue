class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_current_user
  before_action :authenticate_user!
  
  helper_method :current_user

  private


  def set_current_user
    return if session[:user_id].blank?
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def current_user
    @current_user
  end

  def authenticate_user!
    return if current_user.present?

    respond_to do |format|
      format.html { redirect_to login_path, alert: "Please sign in" }
      format.json { render json: { error: "unauthorized" }, status: :unauthorized }
      format.any  { head :unauthorized }
    end
  end
end
