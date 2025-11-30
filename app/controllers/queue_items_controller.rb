require_relative '../services/dynamic_pricing_service'
require_relative '../services/queue_position_service'

class QueueItemsController < ApplicationController
  before_action :set_queue_item, only: [:show, :vote, :upvote, :downvote, :destroy]

  # GET /queue_items
  def index
    unless params[:queue_session_id].present?
      render json: { error: 'queue_session_id required' }, status: :unprocessable_entity
      return
    end
    
    @queue_items = QueueItem.where(queue_session_id: params[:queue_session_id], status: 'pending')
                            .by_position
    
    render json: @queue_items.map { |qi| format_queue_item(qi) }
  end

  # GET /queue_items/:id
  def show
    render json: format_queue_item(@queue_item)
  end

  # POST /queue_items
  def create
    # Handle both search form params and structured queue_item params
    if params[:queue_item].present?
      queue_item_params = parse_queue_item_params
      
      qi = QueueItem.new(
        song_id: queue_item_params[:song_id],
        queue_session_id: queue_item_params[:queue_session_id],
        user: current_user,
        base_price_cents: (queue_item_params[:base_price].to_f * 100).to_i,
        vote_count: 0,
        vote_score: 0,
        base_priority: 0,
        status: 'pending'
      )
    else
      # Handle search form params (spotify_id, title, artist, etc.)
      song = Song.find_or_create_by(spotify_id: params[:spotify_id]) do |s|
        s.title = params[:title]
        s.artist = params[:artist]
        s.cover_url = params[:cover_url]
        s.duration_ms = params[:duration_ms]
        s.preview_url = params[:preview_url]
      end

      queue_session = current_queue_session
      
      # Ensure we have an active queue session
      unless queue_session
        flash[:alert] = "No active queue session found"
        redirect_back(fallback_location: search_path)
        return
      end
      
      # Get desired position and payment info
      desired_position = params[:desired_position]&.to_i || queue_session.songs_count + 1
      # Handle NaN case from JavaScript
      paid_amount_cents = params[:paid_amount_cents].to_s == 'NaN' ? 0 : (params[:paid_amount_cents]&.to_i || 0)
      
      # Calculate required price
      calculated_price = DynamicPricingService.calculate_position_price(queue_session, desired_position)
      
      # Check user balance
      unless current_user.has_sufficient_balance?(calculated_price)
        respond_to do |format|
          format.html do
            flash[:alert] = "Insufficient balance. You have #{current_user.balance_display}, but need $#{'%.2f' % (calculated_price / 100.0)}"
            redirect_back(fallback_location: search_path)
          end
          format.json do
            render json: { error: "Insufficient balance", balance: current_user.balance_cents, required: calculated_price }, status: :payment_required
          end
        end
        return
      end

      qi = QueueItem.new(
        song: song,
        queue_session: queue_session,
        user: current_user,
        base_price_cents: calculated_price,
        position_paid_cents: paid_amount_cents,
        position_guaranteed: desired_position,
        inserted_at_position: desired_position,
        vote_count: 0,
        vote_score: 0,
        base_priority: 0,
        status: 'pending'
      )
    end
    
    if qi.save
      begin
        # Debit user balance only if there's a cost
        if calculated_price > 0
          Rails.logger.info "Debiting user #{current_user.id} balance: #{calculated_price} cents"
          Rails.logger.info "Current balance before: #{current_user.balance_cents} cents"
          
          current_user.debit_balance!(
            calculated_price, 
            description: "Queue: #{song.title} - Position #{desired_position}",
            queue_item: qi
          )
          
          Rails.logger.info "Balance after debit: #{current_user.reload.balance_cents} cents"
        else
          Rails.logger.info "Free queue addition for user #{current_user.id} (no competition)"
        end
        
        # Handle position insertion with potential refunds
        if qi.position_guaranteed && qi.position_paid_cents
          QueuePositionService.insert_at_position(qi, qi.position_guaranteed, qi.position_paid_cents)
        end
        
        respond_to do |format|
          format.html { redirect_to queue_path, notice: "Song added to queue! Balance: #{current_user.reload.balance_display}" }
          format.json { render json: format_queue_item(qi).merge(user_balance: current_user.balance_cents), status: :created }
        end
      rescue => e
        # Rollback queue item if payment fails
        qi.destroy
        respond_to do |format|
          format.html do
            flash[:alert] = "Payment failed: #{e.message}"
            redirect_back(fallback_location: search_path)
          end
          format.json { render json: { error: e.message }, status: :unprocessable_entity }
        end
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
    @queue_item.increment!(:vote_count)

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
    delta = params[:delta].to_i
    
    @queue_item.vote_count = (@queue_item.vote_count || 0) + delta
    @queue_item.vote_score = (@queue_item.vote_score || 0) + delta
    
    if @queue_item.save
      render json: { votes: @queue_item.vote_count }, status: :ok
    else
      render json: { error: "Could not update vote" }, status: :unprocessable_entity
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

  def parse_queue_item_params
    if params[:queue_item].is_a?(String)
      JSON.parse(params[:queue_item]).with_indifferent_access
    else
      params.require(:queue_item).permit(:song_id, :queue_session_id, :base_price)
    end
  end



  def format_queue_item(qi)
    {
      id: qi.id,
      song_id: qi.song_id,
      queue_session_id: qi.queue_session_id,
      user_id: qi.user_id,
      price_for_display: "$#{'%.2f' % qi.base_price}",
      vote_count: qi.vote_count,
      vote_score: qi.vote_score,
      base_priority: qi.base_priority,
      status: qi.status,
      created_at: qi.created_at,
      updated_at: qi.updated_at,
      position_guaranteed: qi.position_guaranteed,
      position_paid_cents: qi.position_paid_cents,
      effective_cost_cents: qi.effective_cost,
      refund_amount_cents: qi.refund_amount_cents,
      current_position: qi.current_position_in_queue,
      was_bumped: qi.was_bumped?,
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
