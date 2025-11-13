# app/controllers/main_controller.rb
class MainController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @queue_session = current_queue_session
  end
end