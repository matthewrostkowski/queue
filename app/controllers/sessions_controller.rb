class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :destroy]
  skip_forgery_protection if -> { request.format.json? }

  def create
    provider     = params[:provider].presence || "guest"
    display_name = params[:display_name].presence || "Guest #{SecureRandom.hex(3)}"

    user = User.find_or_create_by!(auth_provider: provider) { |u| u.display_name = display_name }
    session[:user_id] = user.id

    respond_to do |format|
      format.html { redirect_to mainpage_path, notice: "Welcome, #{user.display_name}" }
      format.json { render json: { id: user.id, display_name: user.display_name, provider: user.auth_provider }, status: :ok }
    end
  end

  def destroy
    reset_session
    respond_to do |format|
      format.html { redirect_to login_path, status: :see_other, notice: "Signed out" }
      format.json { head :no_content }
    end
  end
end
