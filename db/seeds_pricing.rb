# db/seeds_pricing.rb
# Simulation data for testing dynamic pricing

puts "Creating pricing simulation data..."

# Create venue with pricing enabled
venue = Venue.find_or_create_by!(name: "The Jazz Club") do |v|
  v.location = "123 Music Ave, New York, NY"
  v.capacity = 300
  v.pricing_enabled = true
  v.base_price_cents = 200  # $2 base
  v.min_price_cents = 10    # $0.10 minimum
  v.max_price_cents = 50000 # $500 maximum
  v.price_multiplier = 1.0
  v.peak_hours_start = 19   # 7 PM
  v.peak_hours_end = 23     # 11 PM
  v.peak_hours_multiplier = 1.5
end

puts "Created venue: #{venue.name}"

# Create active queue session
session = QueueSession.find_or_create_by!(venue: venue, is_active: true) do |s|
  s.access_code = "JAZZ#{rand(1000..9999)}"
  s.playback_started_at = 30.minutes.ago
  s.last_activity_at = Time.current
end

puts "Created queue session: #{session.access_code}"

# Create different user personas
users = []

# Heavy users (frequent contributors)
5.times do |i|
  users << User.create!(
    display_name: "PowerUser#{i + 1}",
    email: "power#{i + 1}@example.com",
    auth_provider: "google_oauth2",
    auth_uid: "power_#{SecureRandom.hex(8)}"
  )
end

# Regular users
10.times do |i|
  users << User.create!(
    display_name: "RegularUser#{i + 1}",
    email: "regular#{i + 1}@example.com",
    auth_provider: "google_oauth2",
    auth_uid: "regular_#{SecureRandom.hex(8)}"
  )
end

# Occasional users
15.times do |i|
  users << User.create!(
    display_name: "CasualUser#{i + 1}",
    email: "casual#{i + 1}@example.com",
    auth_provider: "guest",
    auth_uid: "casual_#{SecureRandom.hex(8)}"
  )
end

puts "Created #{users.count} users"

# Create songs with realistic metadata
songs = []
artists = ["Miles Davis", "John Coltrane", "Bill Evans", "Chet Baker", "Nina Simone", 
           "Ella Fitzgerald", "Duke Ellington", "Charlie Parker", "Thelonious Monk", 
           "Billie Holiday"]

50.times do |i|
  songs << Song.create!(
    title: "Jazz Standard ##{i + 1}",
    artist: artists.sample,
    spotify_id: "spotify_#{SecureRandom.hex(11)}",
    duration_ms: rand(180000..420000), # 3-7 minutes
    preview_url: "https://preview.spotify.com/track/#{SecureRandom.hex(11)}",
    cover_url: "https://i.scdn.co/image/#{SecureRandom.hex(20)}"
  )
end

puts "Created #{songs.count} songs"

# Simulate queue activity over time
puts "Simulating queue activity..."

# Phase 1: Low activity (30-20 minutes ago)
puts "- Phase 1: Low activity"
5.times do |i|
  user = users.sample
  song = songs.sample
  
  qi = QueueItem.create!(
    song: song,
    queue_session: session,
    user: user,
    created_at: rand(30..20).minutes.ago,
    base_price_cents: 100,
    position_paid_cents: 100,
    position_guaranteed: i + 1,
    inserted_at_position: i + 1,
    vote_count: rand(0..3),
    base_priority: i,
    status: 'pending'
  )
end

# Phase 2: Moderate activity (20-10 minutes ago)
puts "- Phase 2: Moderate activity"
15.times do |i|
  user = users.sample
  song = songs.sample
  position = rand(1..8)
  paid_amount = position == 1 ? rand(500..1500) : rand(200..800)
  
  qi = QueueItem.create!(
    song: song,
    queue_session: session,
    user: user,
    created_at: rand(20..10).minutes.ago,
    base_price_cents: paid_amount,
    position_paid_cents: paid_amount,
    position_guaranteed: position,
    inserted_at_position: position,
    vote_count: rand(0..10),
    base_priority: 5 + i,
    status: 'pending'
  )
  
  # Simulate some refunds for bumped items
  if rand < 0.3 && paid_amount > 500
    qi.update!(refund_amount_cents: rand(100..300))
  end
end

# Phase 3: High activity (last 10 minutes)
puts "- Phase 3: High activity (surge pricing)"
25.times do |i|
  user = users[0..14].sample # More concentrated user base
  song = songs.sample
  position = rand(1..5)
  
  # Calculate dynamic price
  price = DynamicPricingService.calculate_position_price(session, position)
  
  qi = QueueItem.create!(
    song: song,
    queue_session: session,
    user: user,
    created_at: rand(10..0).minutes.ago,
    base_price_cents: price,
    position_paid_cents: price,
    position_guaranteed: position,
    inserted_at_position: position,
    vote_count: rand(5..20),
    base_priority: 20 + i,
    status: 'pending'
  )
end

# Mark some songs as played
puts "Marking some songs as played..."
played_count = 5
session.queue_items.order(:created_at).limit(played_count).each_with_index do |item, idx|
  item.update!(
    played_at: (played_count - idx).minutes.ago,
    status: 'played'
  )
end

# Update queue priorities
puts "Reorganizing queue based on position bids..."
QueuePositionService.insert_at_position(session.queue_items.pending.last, 1, 5000) if session.queue_items.pending.any?

# Create a second, less active venue
venue2 = Venue.create!(
  name: "The Quiet Lounge",
  location: "456 Calm St, Boston, MA",
  pricing_enabled: true,
  base_price_cents: 50,
  min_price_cents: 1,
  max_price_cents: 10000,
  price_multiplier: 0.5
)

session2 = QueueSession.create!(
  venue: venue2,
  is_active: true,
  access_code: "QUIET#{rand(1000..9999)}"
)

# Add just a few items to show contrast
3.times do |i|
  QueueItem.create!(
    song: songs.sample,
    queue_session: session2,
    user: users.sample,
    base_price_cents: 50,
    vote_count: 0,
    base_priority: i,
    status: 'pending'
  )
end

puts "\nSimulation complete!"
puts "Active session stats:"
puts "- Venue: #{venue.name}"
puts "- Access code: #{session.access_code}"
puts "- Total items: #{session.queue_items.count}"
puts "- Pending items: #{session.queue_items.pending.count}"
puts "- Active users (last 5 min): #{DynamicPricingService.get_active_user_count(session)}"
puts "- Queue velocity: #{DynamicPricingService.get_queue_velocity(session).round(2)} songs/min"
puts "- Current price for position 1: $#{'%.2f' % (DynamicPricingService.calculate_position_price(session, 1) / 100.0)}"
