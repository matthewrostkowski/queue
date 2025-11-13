# app/controllers/songs_controller.rb
class SongsController < ApplicationController
  require 'net/http'
  require 'json'

  before_action :authenticate_user!

  def search
    @query = params[:q]
    
    respond_to do |format|
      format.html do
        @results = []
        if @query.present?
          @results = search_deezer(@query)
        end
      end
      format.json do
        if @query.present?
          # Search in database first
          results = Song.where("LOWER(title) LIKE ? OR LOWER(artist) LIKE ?", 
                               "%#{@query.downcase}%", "%#{@query.downcase}%")
                        .limit(5)
                        .map do |song|
            {
              id: song.id,
              spotify_id: song.spotify_id,
              title: song.title,
              artist: song.artist,
              cover_url: song.cover_url,
              duration_ms: song.duration_ms,
              preview_url: song.preview_url
            }
          end
          render json: { results: results }
        else
          render json: { results: [] }
        end
      end
    end
  end

  def index
    @songs = Song.all
  end

  def show
    @song = Song.find(params[:id])
  end

  private

  def search_deezer(query)
    uri = URI("https://api.deezer.com/search")
    uri.query = URI.encode_www_form({ q: query, limit: 20 })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
    
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == '200'
      data = JSON.parse(response.body)
      tracks = data['data'] || []
      
      tracks.map do |track|
        {
          spotify_id: track['id'].to_s,
          title: track['title'],
          artist: track.dig('artist', 'name'),
          cover_url: track.dig('album', 'cover_medium') || track.dig('album', 'cover_big'),
          duration_ms: (track['duration'] * 1000).to_i,
          preview_url: track['preview']
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

