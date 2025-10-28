class SongsController < ApplicationController
  before_action :require_user!

 def search
    q = params[:q].to_s.downcase
    results = Song.where('LOWER(title) LIKE ? OR LOWER(artist) LIKE ?', "%#{q}%", "%#{q}%")
                  .limit(5).map { |s| s.as_json(only: [:id, :title, :artist, :cover_url]) }
    render json: { results: results }
  end
end
