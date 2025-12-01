# lib/tasks/queue.rake
namespace :queue do
  desc "Clear all queue items (for development)"
  task clear: :environment do
    count = QueueItem.count
    
    # Clear foreign key references FIRST
    QueueSession.update_all(currently_playing_id: nil)
    
    # Now delete queue items
    QueueItem.delete_all
    
    # Reset session state
    QueueSession.update_all(playback_started_at: nil)
    
    puts "✅ Deleted #{count} queue items and reset sessions"
  end
end

