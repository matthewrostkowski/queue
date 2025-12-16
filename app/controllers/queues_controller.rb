# app/controllers/queues_controller.rb
class QueuesController < ApplicationController
  before_action :set_queue_session, only: [:show, :start_playback, :stop_playback, :next_track, :queue_state]

  # GET /queue
  def show
    Rails.logger.info "=" * 80
    Rails.logger.info "[QUEUES] show action START"
    Rails.logger.info "[QUEUES] session[:current_queue_session_id] = #{session[:current_queue_session_id].inspect}"
    Rails.logger.info "[QUEUES] @queue_session.id = #{@queue_session&.id}"
    Rails.logger.info "[QUEUES] @queue_session.join_code = #{@queue_session&.join_code}"
    Rails.logger.info "[QUEUES] @queue_session.venue = #{@queue_session&.venue&.name}"
    
    # IMPORTANT: Only get queue items for THIS specific session
    # Order by vote_score DESC (highest votes first)
    @queue_items = @queue_session.queue_items
                                 .where(played_at: nil)
                                 .order(vote_score: :desc, created_at: :asc)
    
    Rails.logger.info "[QUEUES] Found #{@queue_items.count} queue items for session #{@queue_session.id}"
    
    # Log queue order for debugging
    @queue_items.each_with_index do |item, idx|
      Rails.logger.info "[QUEUES]   position=#{idx + 1} id=#{item.id} title=#{item.title.inspect} vote_score=#{item.vote_score} queue_session_id=#{item.queue_session_id}"
    end

    # Calculate jump-ahead prices for each item (if DynamicPricingService exists)
    if defined?(DynamicPricingService)
      @queue_items.each_with_index do |item, index|
        position = index + 1
        item.instance_variable_set(:@jump_ahead_price, 
          DynamicPricingService.calculate_position_price(@queue_session, position))
      end
    end

    # Get currently playing track for THIS session only
    @now_playing = @queue_session.queue_items.find_by(is_currently_playing: true)
    Rails.logger.info "[QUEUES] @now_playing = #{@now_playing&.id} (#{@now_playing&.title})"
    
    # Get access code for display
    @access_code = @queue_session.join_code
    Rails.logger.info "[QUEUES] @access_code = #{@access_code}"
    
    Rails.logger.info "[QUEUES] show action END - rendering #{@queue_items.count} items"
    Rails.logger.info "=" * 80
  end

  # POST /queue/start_playback
  def start_playback
    Rails.logger.info "=" * 80
    Rails.logger.info "[QUEUES] start_playback for session #{@queue_session&.id}"
    
    # Pick next unplayed song by vote_score (highest first) from THIS session
    next_song = @queue_session.queue_items
                              .where(played_at: nil)
                              .order(vote_score: :desc, created_at: :asc)
                              .first

    Rails.logger.info "[QUEUES] next_song = #{next_song&.id} (#{next_song&.title}) vote_score=#{next_song&.vote_score}"
    Rails.logger.info "[QUEUES] preview_url present? #{next_song&.preview_url.present?}"

    if next_song
      # Mark as playing
      next_song.update!(
        played_at: Time.current,
        is_currently_playing: true
      )
      Rails.logger.info "[QUEUES] Marked song #{next_song.id} as playing"

      if next_song.preview_url.present?
        Rails.logger.info "[QUEUES] Returning song with preview_url"
        render json: {
          success: true,
          song: format_song(next_song),
          message: "Playing #{next_song.title}"
        }
      else
        Rails.logger.warn "[QUEUES] Song has no preview URL!"
        render json: {
          success: false,
          message: "No preview available for this track"
        }, status: :unprocessable_entity
      end
    else
      Rails.logger.warn "[QUEUES] Queue is empty!"
      render json: {
        success: false,
        message: "Queue is empty"
      }, status: :unprocessable_entity
    end
    Rails.logger.info "=" * 80
  end

  # POST /queue/stop_playback
  def stop_playback
    Rails.logger.info "[QUEUES] stop_playback for session #{@queue_session&.id}"
    
    # Clear currently playing for this session
    @queue_session.queue_items.update_all(is_currently_playing: false)
    @queue_session.stop_playback! if @queue_session.respond_to?(:stop_playback!)

    render json: {
      success: true,
      message: "Playback stopped"
    }
  end

  # POST /queue/next_track
  def next_track
    Rails.logger.info "=" * 80
    Rails.logger.info "[QUEUES] next_track for session #{@queue_session&.id}"
    
    # Clear current playing status
    @queue_session.queue_items.where(is_currently_playing: true).update_all(is_currently_playing: false)
    
    # Get next unplayed song by vote_score from THIS session
    next_song = @queue_session.queue_items
                              .where(played_at: nil)
                              .order(vote_score: :desc, created_at: :asc)
                              .first

    Rails.logger.info "[QUEUES] next_song = #{next_song&.id} (#{next_song&.title})"

    if next_song
      next_song.update!(
        played_at: Time.current,
        is_currently_playing: true
      )
      Rails.logger.info "[QUEUES] Marked song #{next_song.id} as playing"

      if next_song.preview_url.present?
        render json: {
          success: true,
          song: format_song(next_song)
        }
      else
        Rails.logger.warn "[QUEUES] Song has no preview URL, skipping..."
        render json: {
          success: false,
          message: "No more tracks in queue with previews"
        }, status: :unprocessable_entity
      end
    else
      Rails.logger.info "[QUEUES] No more songs in queue"
      render json: {
        success: false,
        message: "No more songs in queue"
      }, status: :unprocessable_entity
    end
    Rails.logger.info "=" * 80
  end

  # GET /queue/state (for polling)
  def state
    Rails.logger.debug "[QUEUES] state for session #{@queue_session&.id}"
    render json: {
      is_playing: @queue_session.respond_to?(:is_playing) ? @queue_session.is_playing : false,
      currently_playing: currently_playing_json,
      queue: upcoming_queue_json
    }
  end
  
  alias_method :queue_state, :state

  private

  def set_queue_session
    Rails.logger.info "[QUEUES] set_queue_session called"
    Rails.logger.info "[QUEUES]   params[:session_id] = #{params[:session_id].inspect}"
    Rails.logger.info "[QUEUES]   session[:current_queue_session_id] = #{session[:current_queue_session_id].inspect}"

    # If a session_id is passed, it means the user is trying to switch queues.
    # We should honor this and update their main session cookie.
    if params[:session_id].present?
      new_session = QueueSession.find_by(id: params[:session_id])
      if new_session
        Rails.logger.info "[QUEUES]   Found session via params[:session_id]: #{new_session.id}. Updating session cookie."
        set_current_queue_session(new_session) # This updates session[:current_queue_session_id]
      else
        Rails.logger.warn "[QUEUES]   session_id=#{params[:session_id]} passed in params but not found. Ignoring."
      end
    end
    
    # First try to get from session (set when user joins a queue)
    if session[:current_queue_session_id].present?
      @queue_session = QueueSession.find_by(id: session[:current_queue_session_id])
      Rails.logger.info "[QUEUES]   Found session from cookie: #{@queue_session&.id} (#{@queue_session&.join_code})"
    end
    
    # If not in session, try current_queue_session helper from ApplicationController
    if @queue_session.nil? && respond_to?(:current_queue_session, true)
      @queue_session = current_queue_session
      Rails.logger.info "[QUEUES]   Found session from current_queue_session: #{@queue_session&.id}"
    end
    
    # Last resort - get first active session (not ideal but prevents errors)
    if @queue_session.nil?
      @queue_session = QueueSession.where(status: 'active').order(:id).first
      Rails.logger.warn "[QUEUES]   FALLBACK to first active session: #{@queue_session&.id}"
    end
    
    Rails.logger.info "[QUEUES]   Final @queue_session = #{@queue_session&.id} (#{@queue_session&.join_code})"

    unless @queue_session
      Rails.logger.error "[QUEUES] No active queue session found!"
      redirect_to root_path, alert: "No active queue session. Please join a queue first."
    end
  end

  def format_song(song)
    {
      id: song.id,
      title: song.title,
      artist: song.artist,
      cover_url: song.cover_url,
      duration_ms: song.duration_ms,
      preview_url: song.preview_url,
      vote_score: song.vote_score
    }
  end

  def track_json(queue_item)
    {
      id: queue_item.id,
      title: queue_item.title,
      artist: queue_item.artist,
      cover_url: queue_item.cover_url,
      preview_url: queue_item.preview_url,
      duration_ms: queue_item.duration_ms,
      vote_score: queue_item.vote_score,
      vote_count: queue_item.vote_count
    }
  end

  def queue_item_json(item)
    {
      id: item.id,
      title: item.title,
      artist: item.artist,
      cover_url: item.cover_url,
      preview_url: item.preview_url,
      duration_ms: item.duration_ms,
      vote_score: item.vote_score,
      vote_count: item.vote_count,
      user: item.user&.display_name || item.user_display_name || 'Guest',
      is_currently_playing: item.is_currently_playing,
      queue_session_id: item.queue_session_id
    }
  end

  def currently_playing_json
    now_playing_item = @queue_session.queue_items
                                     .find_by(is_currently_playing: true)

    return nil unless now_playing_item

    {
      id: now_playing_item.id,
      title: now_playing_item.title,
      artist: now_playing_item.artist,
      cover_url: now_playing_item.cover_url,
      preview_url: now_playing_item.preview_url,
      played_at: now_playing_item.played_at
    }
  end

  def upcoming_queue_json
    @queue_session.queue_items
                  .where(played_at: nil)
                  .order(vote_score: :desc, created_at: :asc)
                  .map { |item| queue_item_json(item) }
  end
end