# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    redirect_to mainpage_path if current_user
  end

  def create
    # Handle guest login from button submit or JSON params
    if params[:provider] == 'guest' || params[:commit] == 'Continue as guest'
      display_name = params[:display_name] || "Guest"
      user = User.find_or_create_guest(display_name)
      session[:user_id] = user.id
      
      if request.format.json?
        render json: user, status: :ok
      else
        redirect_to mainpage_path, notice: "Logged in as #{user.display_name}"
      end
      return
    end

    # Handle email/password login
    email = params[:email] || params[:user]&.dig(:email)
    password = params[:password] || params[:user]&.dig(:password)
    
    user = User.find_by(email: email)
    
    if user&.authenticate(password)
      session[:user_id] = user.id
      redirect_to mainpage_path, notice: "Welcome back, #{user.display_name}!"
    else
      redirect_to login_path, alert: "Invalid email or password"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "You have been logged out"
  end
end