class ProfilesController < ApplicationController
  before_action :require_user!  # 未登入就擋掉

  def show
    @user = current_user
  end
end
