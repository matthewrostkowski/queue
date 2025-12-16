# app/controllers/admin/venues_controller.rb
module Admin
  class VenuesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_venue, only: [:show, :edit, :update, :update_pricing]

    def index
      @venues = Venue.all.order(:name)
    end

    def show
      @active_sessions = @venue.queue_sessions.active
      @total_sessions = @venue.queue_sessions.count
    end

    def new
      @venue = Venue.new
    end

    def create
      @venue = Venue.new(venue_params)
      # Admin can create venues, but they need a host_user. Use current_user if no host_user_id provided
      @venue.host_user_id ||= current_user.id if @venue.host_user_id.blank?
      if @venue.save
        redirect_to admin_venues_path, notice: 'Venue was successfully created.'
      else
        render :new
      end
    end

    def edit
      # Edit form for venue including pricing settings
    end

    def update
      if @venue.update(venue_params)
        redirect_to admin_venues_path, notice: 'Venue was successfully updated.'
      else
        render :edit
      end
    end

    def update_pricing
      if @venue.update(pricing_params)
        redirect_to edit_admin_venue_path(@venue), notice: 'Pricing settings updated successfully.'
      else
        redirect_to edit_admin_venue_path(@venue), alert: 'Failed to update pricing settings.'
      end
    end

    private

    def set_venue
      @venue = Venue.find(params[:id])
    end

    def venue_params
      params.require(:venue).permit(:name, :location, :capacity, :host_user_id)
    end

    def pricing_params
      params.require(:venue).permit(
        :pricing_enabled,
        :base_price_cents,
        :min_price_cents,
        :max_price_cents,
        :price_multiplier,
        :peak_hours_start,
        :peak_hours_end,
        :peak_hours_multiplier
      )
    end

    def require_admin!
      unless current_user&.admin?
        flash[:alert] = "You must be an admin to access this page"
        redirect_to root_path
      end
    end
  end
end
