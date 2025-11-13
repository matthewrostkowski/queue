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

puts "Seeded: venue=#{v.name}, session=#{qs.id}, user=#{u.display_name}"
