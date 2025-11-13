# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:new, :create]
  
  def show
    @user = current_user
    if @user.nil?
      redirect_to login_path, alert: "Please log in to view your profile"
      return
    end
  end

  def new
    redirect_to profile_path if current_user
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.auth_provider = 'email'
    
    if @user.save
      session[:user_id] = @user.id
      redirect_to mainpage_path, notice: "Account created successfully!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :display_name)
  end
end