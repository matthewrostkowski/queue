class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :destroy, :omniauth]
  #skip_before_action :set_current_user, only: [:create, :omniauth]
  skip_forgery_protection only: [:omniauth]

  skip_forgery_protection if -> { request.format.json? }

  def create
    provider = params[:provider].presence || "guest"

    if provider == "general_user"
      raw_email = params[:email].to_s
      canonical = canonicalize_email(raw_email)

      user = User.find_by(canonical_email: canonical, auth_provider: "general_user")

      if user&.authenticate(params[:password].to_s)
        reset_session
        session[:user_id] = user.id
        respond_to do |format|
          format.html { redirect_to after_sign_in_path, notice: "Welcome back, #{user.display_name}" }
          format.json { render json: { id: user.id, display_name: user.display_name, auth_provider: user.auth_provider }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to login_path, alert: "Invalid email or password" }
          format.json { render json: { error: "invalid_credentials" }, status: :unauthorized }
        end
      end
    else
      reset_session
      display_name = params[:display_name].presence || "Guest #{SecureRandom.hex(3)}"

      user = User.find_by(auth_provider: "guest", display_name: display_name)
      unless user
        user = User.new(auth_provider: "guest", display_name: display_name)
        user.save!(validate: false)
      end

      session[:user_id] = user.id
      respond_to do |format|
        format.html { redirect_to after_sign_in_path, notice: "Welcome, #{user.display_name}" }
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

  def omniauth
    auth = request.env["omniauth.auth"]
    return redirect_to(login_path, alert: "Google sign-in failed") if auth.blank?

    email = auth.info&.email&.downcase
    name  = auth.info&.name || "Google User"

    user = User.find_or_initialize_by(auth_provider: "google_oauth2", email: email)
    user.display_name ||= name
    user.save!

    reset_session
    session[:user_id] = user.id
    redirect_to mainpage_path, notice: "Welcome, #{user.display_name}"
  rescue => e
    Rails.logger.error("[omniauth] #{e.class}: #{e.message}")
    redirect_to login_path, alert: "Google sign-in failed"
  end

  private

  def canonicalize_email(raw)
    return nil if raw.blank?
    email = raw.to_s.strip.downcase
    local, domain = email.split("@", 2)
    return email unless local && domain

    local = local.split("+", 2)[0]
    local = local.delete(".")
    "#{local}@#{domain}"
  end
end
