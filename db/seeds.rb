# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Demo venue + session
v = Venue.find_or_create_by!(name: 'Demo Venue', location: '123 Broadway, NYC', capacity: 100)
qs = QueueSession.find_or_create_by!(venue: v, is_active: true)

u = User.find_or_create_by!(display_name: 'Guest', auth_provider: 'guest')

songs = [
  { title: 'Blinding Lights', artist: 'The Weeknd', cover_url: 'https://i.imgur.com/cover1.png' },
  { title: 'Levitating', artist: 'Dua Lipa', cover_url: 'https://i.imgur.com/cover2.png' },
  { title: 'Uptown Funk', artist: 'Mark Ronson ft. Bruno Mars', cover_url: 'https://i.imgur.com/cover3.png' }
]
songs.each { |attrs| Song.find_or_create_by!(attrs) }

# Create queue items with different vote counts for each song
song_data = [
  { song: Song.find_by(title: 'Blinding Lights'), votes: 15, price: 3.99, status: 'pending' },
  { song: Song.find_by(title: 'Levitating'), votes: 8, price: 4.99, status: 'pending' },
  { song: Song.find_by(title: 'Uptown Funk'), votes: 23, price: 2.99, status: 'played' }
]

song_data.each do |data|
  # Use find_or_initialize_by to update existing records or create new ones
  queue_item = QueueItem.find_or_initialize_by(
    song: data[:song],
    queue_session: qs,
    user: u
  )
  
  # Ensure all queue items have non-zero vote counts
  queue_item.assign_attributes(
    base_price: data[:price],
    vote_count: [data[:votes], 1].max, # Ensure minimum of 1 vote
    status: data[:status]
  )
  
  queue_item.save!
end

puts "Seeded: venue=#{v.name}, session=#{qs.id}, songs=#{Song.count}, user=#{u.display_name}"
puts "Queue items with votes: Blinding Lights (15), Levitating (8), Uptown Funk (23)"
puts "All songs on user profile now have non-zero upvotes!"
