class SongsController < ApplicationController
<<<<<<< HEAD
 def search
    q = params[:q].to_s.downcase
    results = Song.where('LOWER(title) LIKE ? OR LOWER(artist) LIKE ?', "%#{q}%", "%#{q}%")
                  .limit(5).map { |s| s.as_json(only: [:id, :title, :artist, :cover_url]) }
    render json: { results: results }
=======
  require 'net/http'
  require 'json'

  def search
    @query = params[:q]
    @results = []

    if @query.present?
      @results = search_deezer(@query)
    end
>>>>>>> 5cb46b8 (Song search and playing Queue screen)
  end

  def index
    @songs = Song.all
  end

  def show
    @song = Song.find(params[:id])
  end

  private

  def search_deezer(query)
    # Deezer API - no authentication needed!
    uri = URI("https://api.deezer.com/search")
    uri.query = URI.encode_www_form({ q: query, limit: 20 })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # Fix for macOS SSL certificate issues in development
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
    
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == '200'
      data = JSON.parse(response.body)
      tracks = data['data'] || []
      
      tracks.map do |track|
        {
          spotify_id: track['id'].to_s, # Using Deezer ID
          title: track['title'],
          artist: track.dig('artist', 'name'),
          cover_url: track.dig('album', 'cover_medium') || track.dig('album', 'cover_big'),
          duration_ms: (track['duration'] * 1000).to_i, # Deezer gives seconds
          preview_url: track['preview'] # 30-second preview URL
        }
      end
    else
      Rails.logger.error("Deezer search failed: #{response.code} - #{response.body}")
      []
    end
  rescue => e
    Rails.logger.error("Deezer search error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    []
  end
end