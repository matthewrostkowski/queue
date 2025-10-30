class QueuesController < ApplicationController
  before_action :set_queue_session, only: [:show, :start_playback, :next_track]

  # GET /queue
  def show
    # Get all unplayed items, sorted by vote score (desc) then creation time (asc)
    @queue_items = @queue_session.queue_items
                                  .where(played_at: nil)
                                  .order(vote_score: :desc, created_at: :asc)

    # Optional: Get currently playing track
    @now_playing = @queue_session.queue_items.find_by(is_currently_playing: true)

    respond_to do |format|
      format.html { render :show }
      format.json { render json: { queue_items: @queue_items, now_playing: @now_playing } }
    end
  end

  # POST /queue/start_playback
  def start_playback
    next_item = @queue_session.next_track

    if next_item
      @queue_session.play_track!(next_item)
      
      respond_to do |format|
        format.html { redirect_to queue_path, notice: 'Playback started!' }
        format.json { render json: { success: true, now_playing: next_item }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to queue_path, alert: 'No tracks in queue.' }
        format.json { render json: { error: 'No tracks available' }, status: :unprocessable_entity }
      end
    end
  end

  # POST /queue/next_track
  def next_track
    next_item = @queue_session.play_next!

    if next_item
      respond_to do |format|
        format.html { redirect_to queue_path }
        format.json { render json: { success: true, now_playing: next_item }, status: :ok }
      end
    else
      @queue_session.stop_playback!
      
      respond_to do |format|
        format.html { redirect_to queue_path, notice: 'Queue finished!' }
        format.json { render json: { success: true, message: 'Queue finished' }, status: :ok }
      end
    end
  end

  private

  def set_queue_session
    @queue_session = current_queue_session
  end

  def current_queue_session
    # Get the active queue session or create a default one
    session = QueueSession.active.first || QueueSession.first
    
    unless session
      # Create a default venue and session if none exist
      venue = Venue.first || Venue.create!(name: 'Main Venue')
      session = QueueSession.create!(venue: venue, is_active: true)
    end

    session
  end
end
