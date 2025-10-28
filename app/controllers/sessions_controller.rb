class SessionsController < ApplicationController
  skip_before_action :set_current_user

  def create
    provider = params[:provider].presence || 'guest'
    user = User.find_or_create_by(auth_provider: provider, display_name: params[:display_name].presence || 'Guest')
    session[:user_id] = user.id
    render json: { id: user.id, display_name: user.display_name, provider: user.auth_provider }, status: :ok
  end
end
