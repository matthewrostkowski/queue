require 'rails_helper'

RSpec.describe Venue, type: :model do
  describe 'associations' do
    it 'has many queue_sessions' do
      association = Venue.reflect_on_association(:queue_sessions)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      venue = Venue.new
      expect(venue).not_to be_valid
      expect(venue.errors[:name]).to include("can't be blank")
    end

    it 'is valid with name' do
      venue = Venue.new(name: 'Test Venue')
      expect(venue).to be_valid
    end
  end

  describe 'creation' do
    it 'can be created with all attributes' do
      venue = Venue.create!(
        name: 'Test Venue',
        location: '123 Test St',
        capacity: 100
      )
      expect(venue.name).to eq('Test Venue')
      expect(venue.location).to eq('123 Test St')
      expect(venue.capacity).to eq(100)
    end
  end
end
