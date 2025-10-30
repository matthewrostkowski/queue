class QueueItemsController < ApplicationController

  def index
    session_id = params[:queue_session_id]
    return render json: { error: 'missing queue_session_id' }, status: :unprocessable_entity if session_id.blank?

    items = QueueItem.includes(:song)
                     .where(queue_session_id: session_id, status: 'pending')
                     .order(Arel.sql('vote_count DESC, base_priority DESC, created_at ASC'))

    render json: items.map { |qi|
      {
        id: qi.id,
        song: { id: qi.song.id, title: qi.song.title, artist: qi.song.artist, cover_url: qi.song.cover_url },
        votes: qi.vote_count,
        price_for_display: qi.price_for_display.to_f
      }
    }
  end

  def create
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
      end
    end
  end

  # PATCH /queue_items/:id/vote  { delta: 1 | -1 }
  def vote
    qi = QueueItem.find(params[:id])
    delta = params[:delta].to_i
    qi.vote!(delta)
    render json: { id: qi.id, votes: qi.vote_count }, status: :ok
  end

  private

  def queue_item_params
    params.require(:queue_item).permit(:song_id, :queue_session_id, :base_price)
  end
end
