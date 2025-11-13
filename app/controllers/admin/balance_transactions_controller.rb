# app/controllers/admin/balance_transactions_controller.rb
module Admin
  class BalanceTransactionsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    
    def index
      @users = User.order(created_at: :desc).includes(:balance_transactions)
      @recent_transactions = BalanceTransaction.includes(:user, :queue_item).recent.limit(50)
    end
    
    def show
      @user = User.find(params[:id])
      @transactions = @user.balance_transactions.includes(:queue_item).recent
    end
    
    def add_credit
      @user = User.find(params[:id])
      amount_cents = params[:amount_cents].to_i
      
      if amount_cents > 0
        @user.credit_balance!(
          amount_cents,
          description: "Admin credit by #{current_user.display_name}"
        )
        redirect_to admin_balance_transactions_path, notice: "Added $#{'%.2f' % (amount_cents / 100.0)} to #{@user.display_name}'s balance"
      else
        redirect_to admin_balance_transactions_path, alert: "Invalid amount"
      end
    end
    
    private
    
    def require_admin!
      unless current_user&.admin?
        flash[:alert] = "You must be an admin to access this page"
        redirect_to root_path
      end
    end
  end
end
