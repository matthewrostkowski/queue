class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :destroy]
  skip_before_action :set_current_user,   only: [:create]
  skip_forgery_protection if -> { request.format.json? }

  def create
    provider = params[:provider].presence || "guest"

    if provider == "general_user"
      email = params[:email].to_s.downcase
      user  = User.find_by(email: email, auth_provider: "general_user")

      if user&.authenticate(params[:password].to_s)
        reset_session
        session[:user_id] = user.id
        respond_to do |format|
          format.html { redirect_to mainpage_path, notice: "Welcome back, #{user.display_name}" }
          format.json { render json: { id: user.id, display_name: user.display_name, auth_provider: user.auth_provider }, status: :ok }
        end
      else
        respond_to do |format|
          format.html do
            redirect_to login_path, alert: "Invalid email or password"
          end
          format.json { render json: { error: "invalid_credentials" }, status: :unauthorized }
        end
      end
    else
      reset_session
      display_name = params[:display_name].presence || "Guest #{SecureRandom.hex(3)}"
      user = User.create!(auth_provider: "guest", display_name: display_name)
      session[:user_id] = user.id

      respond_to do |format|
        format.html { redirect_to mainpage_path, notice: "Welcome, #{user.display_name}" }
        format.json { render json: { id: user.id, display_name: user.display_name, auth_provider: user.auth_provider }, status: :ok }
      end
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
