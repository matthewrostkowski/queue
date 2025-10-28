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
v = Venue.find_or_create_by!(name: 'Demo Venue', address: '123 Broadway, NYC')
qs = QueueSession.find_or_create_by!(venue: v, is_active: true)

u = User.find_or_create_by!(display_name: 'Guest', auth_provider: 'guest')

songs = [
  { title: 'Blinding Lights', artist: 'The Weeknd', cover_url: 'https://i.imgur.com/cover1.png' },
  { title: 'Levitating', artist: 'Dua Lipa', cover_url: 'https://i.imgur.com/cover2.png' },
  { title: 'Uptown Funk', artist: 'Mark Ronson ft. Bruno Mars', cover_url: 'https://i.imgur.com/cover3.png' }
]
songs.each { |attrs| Song.find_or_create_by!(attrs) }

QueueItem.find_or_create_by!(
  song: Song.first, queue_session: qs, user: u, base_price: 1.99, status: 'pending'
)
puts "Seeded: venue=#{v.name}, session=#{qs.id}, songs=#{Song.count}, user=#{u.display_name}"
