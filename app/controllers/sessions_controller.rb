class SessionsController < ApplicationController
  skip_before_action :set_current_user
  skip_forgery_protection if -> { request.format.json? } # 給 JSON 客戶端用（可保留）

  def create
    provider     = params[:provider].presence || "guest"
    display_name = params[:display_name].presence || "Guest #{SecureRandom.hex(3)}"

    user = User.find_or_create_by!(auth_provider: provider) { |u| u.display_name = display_name }
    session[:user_id] = user.id

    respond_to do |format|
      format.html { redirect_to mainpage_path, notice: "Welcome, #{user.display_name}" } # 登入後到 mainpage
      format.json { render json: { id: user.id, display_name: user.display_name, provider: user.auth_provider }, status: :ok }
    end
  end

  def destroy
    reset_session
    respond_to do |format|
      format.html { redirect_to root_path, notice: "Signed out" } # 登出回 login (root)
      format.json { head :no_content }
    end
  end
end
