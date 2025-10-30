class QueueItemsController < ApplicationController
<<<<<<< HEAD
=======
  before_action :set_queue_item, only: [:show, :vote, :upvote, :downvote, :destroy]
>>>>>>> 5cb46b8 (Song search and playing Queue screen)

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
<<<<<<< HEAD
    # Handle both JSON and form submissions
    if params[:queue_item].is_a?(String)
      # Parse JSON string from hidden field
      queue_params = JSON.parse(params[:queue_item])
    else
      # Direct parameters
      queue_params = queue_item_params
    end
    
    qi = QueueItem.new(
      song_id: queue_params['song_id'] || queue_params[:song_id],
      queue_session_id: queue_params['queue_session_id'] || queue_params[:queue_session_id],
      base_price: queue_params['base_price'] || queue_params[:base_price] || 3.99,
      user: current_user,
      status: 'pending',
      vote_count: 0,
      base_priority: 0
    )
    
    if qi.save
      respond_to do |format|
        format.html { redirect_to profile_path, notice: "Song added to queue!" }
        format.json { render json: { id: qi.id, price_for_display: qi.price_for_display.to_f }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to search_path, alert: qi.errors.full_messages.first }
        format.json { render json: { errors: qi.errors.full_messages }, status: :unprocessable_entity }
=======
    @queue_item = QueueItem.new(queue_item_params)
    @queue_item.queue_session = current_queue_session
    @queue_item.vote_score ||= 0
    @queue_item.base_price_cents ||= 100
    @queue_item.status ||= "pending"

    if @queue_item.save
      respond_to do |format|
        format.html { redirect_to queue_path, notice: "Song added to queue!" }
        format.json { render json: @queue_item, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to search_path, alert: "Failed to add song." }
        format.json { render json: { errors: @queue_item.errors.full_messages }, status: :unprocessable_entity }
>>>>>>> 5cb46b8 (Song search and playing Queue screen)
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

  def queue_item_params
    params.permit(
      :song_id,
      :user_id,
      :title,
      :artist,
      :cover_url,
      :duration_ms,
      :preview_url,
      :spotify_id,
      :user_display_name,
      :base_price_cents,
      :vote_score
    )
  end

  def current_queue_session
    QueueSession.active.first || QueueSession.first || create_default_session
  end

  def create_default_session
    venue = Venue.first || Venue.create!(name: "Default Venue")
    QueueSession.create!(venue: venue, is_active: true)
  end
end