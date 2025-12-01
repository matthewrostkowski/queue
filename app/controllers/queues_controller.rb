class QueuesController < ApplicationController
  before_action :set_queue_session, only: [:show, :start_playback, :next_track, :stop_playback, :state]
  before_action :require_queue_session, only: [:show, :start_playback, :next_track, :stop_playback, :state]

  # GET /queue
  def show
    # Get all unplayed items, sorted purely by base_priority (asc)
    # Paid positions are absolute - upvotes don't change visual ordering
    # IMPORTANT: .includes(:song) loads the associated songs to avoid N+1 queries
    @queue_items = @queue_session.queue_items
                                  .includes(:song)
                                  .where(played_at: nil)
                                  .order(:base_priority, :created_at)

    # Calculate jump-ahead pricing for each position
    # This shows the cost to insert a NEW song at this position (jumping ahead of this song)
    @queue_items.each_with_index do |item, index|
      position = index + 1  # Current position in queue (1-based)
      item.instance_variable_set(:@jump_ahead_price,
        DynamicPricingService.calculate_position_price(@queue_session, position))
    end

    # Get currently playing track
    @now_playing = @queue_session.queue_items
                                  .includes(:song)
                                  .find_by(is_currently_playing: true)
                          
    @access_code = @queue_session.join_code

    respond_to do |format|
      format.html { render :show }
      format.json { 
        render json: { 
          queue_items: @queue_items.map { |qi| format_queue_item(qi) },
          now_playing: @now_playing ? format_queue_item(@now_playing) : nil
        } 
      }
    end
  end

  # GET /queue/state
  # Returns current queue state for polling
  def state
    # Get all unplayed items in display order (paid positions only, no vote reordering)
    queue_items = @queue_session.queue_items
                                .includes(:song)
                                .where(played_at: nil)
                                .order(:base_priority, :created_at)

    # Calculate jump-ahead pricing for each position
    # This shows the cost to insert a NEW song at this position (jumping ahead of this song)
    queue_items.each_with_index do |item, index|
      position = index + 1  # Current position in queue (1-based)
      item.instance_variable_set(:@jump_ahead_price,
        DynamicPricingService.calculate_position_price(@queue_session, position))
    end

    # Get currently playing track
    currently_playing = @queue_session.queue_items
                                      .includes(:song)
                                      .find_by(is_currently_playing: true)

    # Check if playback is active
    is_playing = currently_playing.present?

    render json: {
      queue: queue_items.map { |qi| format_queue_item(qi) },
      currently_playing: currently_playing ? format_queue_item(currently_playing) : nil,
      is_playing: is_playing
    }
  end

  # POST /queue/start_playback
  def start_playback
    # Stop any currently playing tracks first
    stop_current_track

    # Get the highest voted unplayed track
    next_item = get_next_queue_item

    if next_item
      play_track!(next_item)
      
      respond_to do |format|
        format.html { redirect_to queue_path, notice: 'Playback started!' }
        format.json { 
          render json: { 
            success: true, 
            track: format_queue_item(next_item),
            message: 'Playback started'
          }, status: :ok 
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to queue_path, alert: 'No tracks in queue.' }
        format.json { 
          render json: { 
            success: false,
            message: 'No tracks in queue'
          }, status: :unprocessable_entity 
        }
      end
    end
  end

  # POST /queue/next_track
  def next_track
    # Mark current track as played and stop it
    current_track = stop_current_track(mark_as_played: true)

    # Get next track according to vote order
    next_item = get_next_queue_item

    if next_item
      play_track!(next_item)
      
      respond_to do |format|
        format.html { redirect_to queue_path }
        format.json { 
          render json: { 
            success: true, 
            track: format_queue_item(next_item),
            previous_track: current_track ? format_queue_item(current_track) : nil
          }, status: :ok 
        }
      end
    else
      # Queue finished
      respond_to do |format|
        format.html { redirect_to queue_path, notice: 'Queue finished!' }
        format.json { 
          render json: { 
            success: true, 
            message: 'Queue finished',
            track: nil
          }, status: :ok 
        }
      end
    end
  end

  # POST /queue/stop_playback
  def stop_playback
    # Stop current track without marking as played
    current_track = stop_current_track(mark_as_played: false)

    respond_to do |format|
      format.html { redirect_to queue_path, notice: 'Playback stopped' }
      format.json { 
        render json: { 
          success: true,
          message: 'Playback stopped'
        }, status: :ok 
      }
    end
  end

  private

  def set_queue_session
    if params[:session_id]
      @queue_session = QueueSession.find_by(id: params[:session_id])

      set_current_queue_session(@queue_session) if @queue_session
    else
      @queue_session = current_queue_session
    end
  end

  def require_queue_session
    if @queue_session.nil?
      respond_to do |format|
        format.html { redirect_to mainpage_path, alert: "No active queue session found." }
        format.json { render json: { error: "No active queue session found." }, status: :not_found }
      end
    end
  end

  # Get the next unplayed track according to priority ordering
  # This ensures paid positions play first, then vote score as tiebreaker
  def get_next_queue_item
    @queue_session.queue_items
                  .includes(:song)
                  .where(played_at: nil, is_currently_playing: false)
                  .order(:base_priority, vote_score: :desc, created_at: :asc)
                  .first
  end

  # Stop the currently playing track
  # Optionally mark it as played
  def stop_current_track(mark_as_played: false)
    current_track = @queue_session.queue_items.find_by(is_currently_playing: true)
    
    if current_track
      if mark_as_played
        current_track.update(
          is_currently_playing: false,
          played_at: Time.current
        )
      else
        current_track.update(is_currently_playing: false)
      end
    end
    
    current_track
  end

  # Mark a track as currently playing
  def play_track!(queue_item)
    # Ensure no other tracks are marked as playing
    @queue_session.queue_items
                  .where(is_currently_playing: true)
                  .where.not(id: queue_item.id)
                  .update_all(is_currently_playing: false)
    
    # Start playing the new track
    queue_item.update(is_currently_playing: true)
    queue_item
  end

  # Format a queue item for JSON response
  # This matches what the JavaScript expects
  def format_queue_item(queue_item)
    song = queue_item.song
    {
      id: queue_item.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      preview_url: song.preview_url,
      cover_url: song.album_cover_url,
      vote_score: queue_item.vote_score,
      created_at: queue_item.created_at,
      is_currently_playing: queue_item.is_currently_playing,
      jump_ahead_price_cents: queue_item.jump_ahead_price_cents,
      jump_ahead_price_display: queue_item.jump_ahead_price_display
    }
  end
end