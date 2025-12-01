# app/controllers/queues_controller.rb
class QueuesController < ApplicationController
  before_action :set_queue_session, only: [:show, :start_playback, :stop_playback, :next_track, :queue_state]

  # GET /queue
  def show
    Rails.logger.info "[QUEUES] show action START session_id=#{@queue_session&.id}"
    
    # IMPORTANT: Order by vote_score DESC (highest votes first)
    @queue_items = @queue_session.queue_items
                                 .where(played_at: nil)
                                 .order(vote_score: :desc, created_at: :asc)
    
    # Log queue order for debugging
    @queue_items.each_with_index do |item, idx|
      Rails.logger.info "[QUEUES] position=#{idx + 1} id=#{item.id} title=#{item.title.inspect} vote_score=#{item.vote_score}"
    end

    # Calculate jump-ahead prices for each item
    @queue_items.each_with_index do |item, index|
      position = index + 1
      item.instance_variable_set(:@jump_ahead_price, 
        DynamicPricingService.calculate_position_price(@queue_session, position))
    end

    # Get currently playing track
    @now_playing = @queue_session.queue_items.find_by(is_currently_playing: true)
    
    # Get access code for display
    @access_code = @queue_session.join_code
    
    Rails.logger.info "[QUEUES] show action END items=#{@queue_items.count} now_playing=#{@now_playing&.id}"
  end

  # POST /queue/start_playback
  def start_playback
    Rails.logger.info "[QUEUES] start_playback session_id=#{@queue_session&.id}"
    
    # Pick next unplayed song by vote_score (highest first)
    next_song = @queue_session.queue_items
                              .where(played_at: nil)
                              .order(vote_score: :desc, created_at: :asc)
                              .first

    Rails.logger.info "[QUEUES] start_playback next_song=#{next_song&.id} title=#{next_song&.title}"

    if next_song
      next_song.update(played_at: Time.current)

      if next_song.preview_url.present?
        render json: {
          success: true,
          song: format_song(next_song),
          message: "Playing #{next_song.title}"
        }
      else
        render json: {
          success: false,
          message: "No preview available for this track"
        }, status: :unprocessable_entity
      end
    else
      render json: {
        success: false,
        message: "Queue is empty"
      }, status: :unprocessable_entity
    end
  end

  # POST /queue/stop_playback
  def stop_playback
    Rails.logger.info "[QUEUES] stop_playback session_id=#{@queue_session&.id}"
    @queue_session.stop_playback! if @queue_session.respond_to?(:stop_playback!)

    render json: {
      success: true,
      message: "Playback stopped"
    }
  end

  # POST /queue/next_track
  def next_track
    Rails.logger.info "[QUEUES] next_track session_id=#{@queue_session&.id}"
    
    next_song = @queue_session.queue_items
                              .where(played_at: nil)
                              .order(vote_score: :desc, created_at: :asc)
                              .first

    Rails.logger.info "[QUEUES] next_track next_song=#{next_song&.id} title=#{next_song&.title}"

    if next_song
      next_song.update(played_at: Time.current)

      if next_song.preview_url.present?
        render json: {
          success: true,
          song: format_song(next_song)
        }
      else
        render json: {
          success: false,
          message: "No more tracks in queue with previews"
        }, status: :unprocessable_entity
      end
    else
      render json: {
        success: false,
        message: "No more songs in queue"
      }, status: :unprocessable_entity
    end
  end

  # GET /queue/state (for polling)
  def queue_state
    render json: {
      is_playing: @queue_session.respond_to?(:is_playing) ? @queue_session.is_playing : false,
      currently_playing: currently_playing_json,
      queue: upcoming_queue_json
    }
  end

  private

  def set_queue_session
    # Use the current_queue_session helper from ApplicationController
    @queue_session = current_queue_session
    
    Rails.logger.info "[QUEUES] set_queue_session resolved session_id=#{@queue_session&.id}"

    unless @queue_session
      Rails.logger.error "[QUEUES] No active queue session found"
      redirect_to root_path, alert: "No active queue session"
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
      is_currently_playing: item.is_currently_playing
    }
  end

  def currently_playing_json
    now_playing_item = @queue_session.queue_items
                                     .where.not(played_at: nil)
                                     .order(played_at: :desc)
                                     .first

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