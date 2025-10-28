class QueueItemsController < ApplicationController
  before_action :require_user!

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
    qi = QueueItem.new(queue_item_params.merge(user: current_user, status: 'pending', vote_count: 0, base_priority: 0))
    if qi.save
      render json: { id: qi.id, price_for_display: qi.price_for_display.to_f }, status: :created
    else
      render json: { errors: qi.errors.full_messages }, status: :unprocessable_entity
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
