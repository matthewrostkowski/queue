class HomeController < ApplicationController
  skip_before_action :set_current_user

  def index
  end
end
