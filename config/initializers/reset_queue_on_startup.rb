# config/initializers/reset_queue_on_startup.rb
#
# This initializer clears all queue items when the Rails server starts.
# This ensures a fresh queue state for development/testing.
#
# NOTE: Remove or disable this in production!

Rails.application.config.after_initialize do
  # Only run in development
  if Rails.env.development?
    # Check if we're running the server (not console, rake, etc.)
    is_server = defined?(Puma) || 
                ENV['RAILS_SERVER_STARTED'] || 
                $0.include?('puma') || 
                $0.include?('server') ||
                (defined?(Rails::Server) rescue false)
    
    if is_server
      begin
        puts "=" * 80
        puts "[STARTUP] Resetting queue items..."
        
        # Count before deletion
        queue_item_count = QueueItem.count
        puts "[STARTUP] Found #{queue_item_count} queue items to delete"
        
        # IMPORTANT: Clear foreign key references FIRST
        # QueueSession.currently_playing_id references queue_items
        QueueSession.update_all(currently_playing_id: nil)
        puts "[STARTUP] Cleared currently_playing_id references"
        
        # Now we can safely delete queue items
        QueueItem.delete_all
        
        # Reset other queue session fields
        update_fields = { playback_started_at: nil }
        update_fields[:is_playing] = false if QueueSession.column_names.include?("is_playing")
        QueueSession.update_all(update_fields)
        
        puts "[STARTUP] Deleted #{queue_item_count} queue items"
        puts "[STARTUP] Reset all queue sessions to clean state"
        puts "[STARTUP] Queue reset complete!"
        puts "=" * 80
      rescue => e
        puts "[STARTUP] Error resetting queue: #{e.message}"
        puts e.backtrace.first(5).join("\n")
      end
    end
  end
end