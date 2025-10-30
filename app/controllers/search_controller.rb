# app/controllers/search_controller.rb
class SearchController < ApplicationController
  def index
    @songs = []
    if params[:q].present?
      # Use LIKE for SQLite compatibility (case-insensitive search)
      @songs = Song.where("LOWER(title) LIKE ? OR LOWER(artist) LIKE ?", 
                         "%#{params[:q].downcase}%", "%#{params[:q].downcase}%")
                   .limit(10)
    end
    
    respond_to do |format|
      format.html
      format.json { render json: @songs }
    end
  end
end
