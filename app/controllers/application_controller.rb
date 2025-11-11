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

  # Require host or admin
  def require_host!
    unless current_user&.host? || current_user&.admin?
      respond_to do |format|
        format.html { redirect_to mainpage_path, alert: "You don't have permission to access this page" }
        format.json { render json: { error: "forbidden" }, status: :forbidden }
        format.any  { head :forbidden }
      end
    end
  end

  # Require admin only
  def require_admin!
    unless current_user&.admin?
      respond_to do |format|
        format.html { redirect_to mainpage_path, alert: "Admin access required" }
        format.json { render json: { error: "forbidden" }, status: :forbidden }
        format.any  { head :forbidden }
      end
    end
  end

  # Redirect after sign-in based on role
  def after_sign_in_path
    return login_path unless current_user

    case current_user.role
    when 'admin'
      admin_dashboard_path
    when 'host'
      host_dashboard_path
    else
      mainpage_path  # Regular user
    end
  end
end
