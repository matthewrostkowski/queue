module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc)
    end

    def promote_to_host
      @user = User.find(params[:id])
      @user.update!(role: :host)
      redirect_to admin_users_path, notice: "#{@user.display_name} is now a host"
    end

    def promote_to_admin
      @user = User.find(params[:id])
      @user.update!(role: :admin)
      redirect_to admin_users_path, notice: "#{@user.display_name} is now an admin"
    end

    def demote
      @user = User.find(params[:id])
      @user.update!(role: :user)
      redirect_to admin_users_path, notice: "#{@user.display_name} demoted to user"
    end
  end
end
