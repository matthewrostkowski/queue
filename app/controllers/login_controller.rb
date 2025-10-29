class LoginController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]


  def index
    redirect_to mainpage_path and return if current_user
  end
end
