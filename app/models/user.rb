class User < ApplicationRecord
  has_many :queue_items, dependent: :nullify
  has_many :queued_songs, through: :queue_items, source: :song
  
  validates :display_name, presence: true
  validates :auth_provider, presence: true

  def total_upvotes_received
    queue_items.sum(:vote_count)
  end


  def queue_summary
    {
      id: id,
      username: display_name,
      queued_count: queue_items.count,
      upvotes_total: total_upvotes_received,
      by_status: queue_items.group(:status).count
    }
  end


  private
  
end