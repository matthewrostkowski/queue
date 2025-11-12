module Admin
  class BaseController < ApplicationController
    before_action :require_admin!  # only admins can access these routes
  end
end