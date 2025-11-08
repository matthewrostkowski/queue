class QueueItemsController < ApplicationController
  before_action :set_queue_item, only: [:show, :upvote, :downvote, :destroy]

  # GET /queue_items
  def index
    @queue_items = QueueItem.unplayed.by_votes
    render json: @queue_items
  end

  # GET /queue_items/:id
  def show
    render json: @queue_item
  end

  # POST /queue_items
  def create
    # First, find or create the Song
    song = Song.find_or_create_by(spotify_id: params[:spotify_id]) do |s|
      s.title = params[:title]
      s.artist = params[:artist]
      s.cover_url = params[:cover_url]
      s.duration_ms = params[:duration_ms]
      s.preview_url = params[:preview_url]
    end

    unless song.persisted?
      respond_to do |format|
        format.html { redirect_to search_path, alert: "Could not save song: #{song.errors.full_messages.join(', ')}" }
        format.json { render json: { errors: song.errors.full_messages }, status: :unprocessable_entity }
      end
      return
    end

    # Get or create the current queue session
    queue_session = current_queue_session

    # Create the QueueItem with schema-correct fields
    qi = QueueItem.new(
      song: song,
      queue_session: queue_session,
      user: current_user,
      base_price_cents: 399,  # 399 cents = $3.99
      vote_count: 0,
      vote_score: 0,
      base_priority: 0,
      status: 'pending'
    )
    
    if qi.save
      respond_to do |format|
        format.html { redirect_to queue_path, notice: "Song added to queue!" }
        format.json { render json: { id: qi.id, song: song }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to search_path, alert: qi.errors.full_messages.first }
        format.json { render json: { errors: qi.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # POST /queue_items/:id/upvote
  def upvote
    @queue_item.increment!(:vote_score)

    respond_to do |format|
      format.html { redirect_to queue_path, notice: "Song upvoted!" }
      format.json { render json: { vote_score: @queue_item.vote_score }, status: :ok }
    end
  end

  # POST /queue_items/:id/downvote
  def downvote
    @queue_item.decrement!(:vote_score)

    respond_to do |format|
      format.html { redirect_to queue_path, notice: "Song downvoted!" }
      format.json { render json: { vote_score: @queue_item.vote_score }, status: :ok }
    end
  end

  # PATCH /queue_items/:id/vote
  def vote
    direction = params[:direction]

    case direction
    when "up"
      @queue_item.update_column(:vote_score, (@queue_item.vote_score || 0) + 1)
    when "down"
      @queue_item.update_column(:vote_score, (@queue_item.vote_score || 0) - 1)
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: queue_path, alert: "Invalid vote direction." }
        format.json { render json: { error: "Invalid direction" }, status: :unprocessable_entity }
      end
      return
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: queue_path, notice: "Vote recorded!" }
      format.json { render json: { vote_score: @queue_item.vote_score }, status: :ok }
    end
  end

  # DELETE /queue_items/:id
  def destroy
    @queue_item.destroy

    respond_to do |format|
      format.html { redirect_to queue_path, notice: "Song removed from queue." }
      format.json { render json: { success: true, message: "Song removed" }, status: :ok }
    end
  end

  private

  def set_queue_item
    @queue_item = QueueItem.find(params[:id])
  end

  def current_queue_session
    QueueSession.where(is_active: true).first || 
    QueueSession.first || 
    create_default_session
  end

  def create_default_session
    venue = Venue.first || Venue.create!(name: "Default Venue")
    QueueSession.create!(venue: venue, is_active: true)
  end
end