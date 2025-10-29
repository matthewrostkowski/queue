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
      username: display_name,
      songs_queued_count: queue_items.count,
      total_upvotes_received: total_upvotes_received
    }
  end

  def profile_picture
    profile_picture_url.presence || default_profile_picture
  end

  private
  
  def default_profile_picture
    "https://ui-avatars.com/api/?name=#{display_namel}&background=1DB954&color=fff&size=200"
  end

end
