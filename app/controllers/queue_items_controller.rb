# app/controllers/queue_items_controller.rb
class QueueItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_queue_item, only: [:show, :destroy, :upvote, :downvote, :vote]

  # GET /queue_items
  def index
    Rails.logger.info "[QUEUE_ITEMS] index action"
    
    # Must have a queue_session_id parameter
    unless params[:queue_session_id].present?
      Rails.logger.error "[QUEUE_ITEMS] Missing queue_session_id parameter"
      render json: { error: "queue_session_id is required" }, status: :unprocessable_entity
      return
    end
    
    qs = QueueSession.find_by(id: params[:queue_session_id])
    unless qs
      Rails.logger.error "[QUEUE_ITEMS] Queue session not found: #{params[:queue_session_id]}"
      render json: { error: "Queue session not found" }, status: :not_found
      return
    end
    
    @queue_items = qs.queue_items
                     .where(played_at: nil)
                     .order(vote_score: :desc, created_at: :asc)
    
    Rails.logger.info "[QUEUE_ITEMS] Found #{@queue_items.count} items for session #{qs.id}"
    
    render json: @queue_items.map { |qi| format_queue_item(qi) }
  end

  # GET /queue_items/:id
  def show
    render json: format_queue_item(@queue_item)
  end

  # POST /queue_items
  def create
    Rails.logger.info "=" * 80
    Rails.logger.info "[QUEUE_ITEMS] create action START"
    Rails.logger.info "[QUEUE_ITEMS] Params: #{params.to_unsafe_h.except(:authenticity_token).inspect}"
    Rails.logger.info "[QUEUE_ITEMS] session[:current_queue_session_id] = #{session[:current_queue_session_id].inspect}"
    
    # Get the current queue session - MUST use the one from user's session
    qs = get_current_queue_session
    
    unless qs
      Rails.logger.error "[QUEUE_ITEMS] No queue session found! User must join a queue first."
      respond_to do |format|
        format.html { redirect_to mainpage_path, alert: "Please join a queue first!" }
        format.json { render json: { error: "No queue session. Join a queue first." }, status: :unprocessable_entity }
      end
      return
    end
    
    Rails.logger.info "[QUEUE_ITEMS] Using queue_session: id=#{qs.id} join_code=#{qs.join_code} venue=#{qs.venue&.name}"
    
    # Build queue item params
    qi_params = {
      queue_session_id: qs.id,
      user_id: current_user&.id,
      user_display_name: current_user&.display_name || params[:user_display_name] || 'Guest',
      title: params[:title],
      artist: params[:artist],
      preview_url: params[:preview_url],
      vote_score: 0,
      vote_count: 0,
      base_priority: 0,
      status: 'pending'
    }
    
    # Handle song association if we have a spotify_id
    if params[:spotify_id].present?
      song = Song.find_or_create_by(spotify_id: params[:spotify_id]) do |s|
        s.title = params[:title]
        s.artist = params[:artist]
        s.cover_url = params[:cover_url]
        s.duration_ms = params[:duration_ms]
        s.preview_url = params[:preview_url]
      end
      qi_params[:song_id] = song.id
      Rails.logger.info "[QUEUE_ITEMS] Song: id=#{song.id} title=#{song.title}"
    end
    
    # Begin a transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      # Handle payment if required
      price_cents = params[:paid_amount_cents].to_i
      if price_cents > 0
        user = current_user
        unless user.has_sufficient_balance?(price_cents)
          raise ActiveRecord::Rollback, "Insufficient balance"
        end

        # Deduct from balance and create a transaction record
        user.debit_balance!(price_cents, description: "Queued song: #{params[:title]}")
        qi_params[:base_price] = price_cents
      end

      # Create the QueueItem
      qi = QueueItem.new(qi_params)
      
      unless qi.save
        # If save fails, the transaction will be rolled back.
        raise ActiveRecord::Rollback, "QueueItem save failed"
      end

      # If everything is successful, send success response
      Rails.logger.info "[QUEUE_ITEMS] ✅ Successfully created QueueItem id=#{qi.id}"
      respond_to do |format|
        format.html { redirect_to queue_path, notice: "Song added! Your new balance: #{user.balance_display}" }
        format.json { render json: format_queue_item(qi).merge(user_balance: user.balance_cents), status: :created }
      end
    end
  rescue ActiveRecord::Rollback => e
    # Handle failures (insufficient balance or save error)
    Rails.logger.error "[QUEUE_ITEMS] ❌ Transaction rolled back: #{e.message}"
    error_message = e.message == "Insufficient balance" ? "You don't have enough funds." : "Could not add song to queue."
    
    respond_to do |format|
      format.html { redirect_to search_path, alert: error_message }
      format.json { render json: { errors: [error_message] }, status: :unprocessable_entity }
    end
    
    Rails.logger.info "[QUEUE_ITEMS] create action END (with error)"
    Rails.logger.info "=" * 80
  end

  # POST /queue_items/:id/upvote
  def upvote
    Rails.logger.info "[QUEUE_ITEMS] upvote id=#{@queue_item.id} current_score=#{@queue_item.vote_score}"
    
    @queue_item.increment!(:vote_score)
    @queue_item.increment!(:vote_count)
    
    Rails.logger.info "[QUEUE_ITEMS] upvote new_score=#{@queue_item.vote_score}"

    respond_to do |format|
      format.html { redirect_to queue_path, notice: "Song upvoted!" }
      format.json { render json: { vote_score: @queue_item.vote_score, id: @queue_item.id }, status: :ok }
    end
  end

  # POST /queue_items/:id/downvote
  def downvote
    Rails.logger.info "[QUEUE_ITEMS] downvote id=#{@queue_item.id} current_score=#{@queue_item.vote_score}"
    
    @queue_item.decrement!(:vote_score)
    
    Rails.logger.info "[QUEUE_ITEMS] downvote new_score=#{@queue_item.vote_score}"

    respond_to do |format|
      format.html { redirect_to queue_path, notice: "Song downvoted!" }
      format.json { render json: { vote_score: @queue_item.vote_score, id: @queue_item.id }, status: :ok }
    end
  end

  # PATCH /queue_items/:id/vote
  def vote
    delta = params[:delta].to_i
    
    Rails.logger.info "[QUEUE_ITEMS] vote id=#{@queue_item.id} delta=#{delta}"
    
    @queue_item.vote_count = (@queue_item.vote_count || 0) + delta
    @queue_item.vote_score = (@queue_item.vote_score || 0) + delta
    
    if @queue_item.save
      Rails.logger.info "[QUEUE_ITEMS] vote saved new_score=#{@queue_item.vote_score}"
      render json: { votes: @queue_item.vote_count, vote_score: @queue_item.vote_score }, status: :ok
    else
      Rails.logger.error "[QUEUE_ITEMS] vote failed: #{@queue_item.errors.full_messages}"
      render json: { error: "Could not update vote" }, status: :unprocessable_entity
    end
  end

  # DELETE /queue_items/:id
  def destroy
    Rails.logger.info "[QUEUE_ITEMS] destroy id=#{@queue_item.id} title=#{@queue_item.title}"
    
    @queue_item.destroy

    respond_to do |format|
      format.html { redirect_to queue_path, notice: "Song removed from queue." }
      format.json { render json: { success: true, message: "Song removed" }, status: :ok }
    end
  end

  private

  def set_queue_item
    @queue_item = QueueItem.find(params[:id])
    Rails.logger.debug "[QUEUE_ITEMS] set_queue_item id=#{@queue_item.id} queue_session_id=#{@queue_item.queue_session_id}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "[QUEUE_ITEMS] QueueItem not found: #{params[:id]}"
    respond_to do |format|
      format.html { redirect_to queue_path, alert: "Song not found" }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  # Get the current queue session from the user's session cookie
  # This is CRITICAL for proper session isolation
  def get_current_queue_session
    Rails.logger.info "[QUEUE_ITEMS] get_current_queue_session"
    Rails.logger.info "[QUEUE_ITEMS]   session[:current_queue_session_id] = #{session[:current_queue_session_id].inspect}"
    
    # First try session cookie
    if session[:current_queue_session_id].present?
      qs = QueueSession.find_by(id: session[:current_queue_session_id])
      if qs
        Rails.logger.info "[QUEUE_ITEMS]   Found from cookie: id=#{qs.id} join_code=#{qs.join_code}"
        return qs
      else
        Rails.logger.warn "[QUEUE_ITEMS]   Session ID in cookie but not found in DB!"
      end
    end
    
    # Try ApplicationController helper if available
    if respond_to?(:current_queue_session, true)
      qs = current_queue_session
      if qs
        Rails.logger.info "[QUEUE_ITEMS]   Found from current_queue_session helper: id=#{qs.id}"
        return qs
      end
    end
    
    Rails.logger.error "[QUEUE_ITEMS]   No queue session found!"
    nil
  end

  def format_queue_item(qi)
    {
      id: qi.id,
      song_id: qi.song_id,
      queue_session_id: qi.queue_session_id,
      user_id: qi.user_id,
      title: qi.title,
      artist: qi.artist,
      cover_url: qi.cover_url,
      preview_url: qi.preview_url,
      duration_ms: qi.duration_ms,
      price_for_display: "$#{'%.2f' % (qi.base_price || 0)}",
      vote_count: qi.vote_count,
      vote_score: qi.vote_score,
      base_priority: qi.base_priority,
      status: qi.status,
      created_at: qi.created_at,
      updated_at: qi.updated_at,
      current_position: qi.current_position_in_queue,
      song: qi.song ? {
        id: qi.song.id,
        title: qi.song.title,
        artist: qi.song.artist,
        cover_url: qi.song.cover_url,
        preview_url: qi.song.preview_url,
        duration_ms: qi.song.duration_ms
      } : nil
    }
  end
end