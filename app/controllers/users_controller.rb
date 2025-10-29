class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :set_current_user,   only: [:create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(auth_provider: "general_user"))
    @user.display_name = @user.display_name.presence || @user.email.to_s.split("@").first

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to mainpage_path, notice: "Welcome, #{@user.display_name}"
    else
      flash.now[:alert] = @user.errors.full_messages.first || "Sign up failed"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :display_name)
  end
end
