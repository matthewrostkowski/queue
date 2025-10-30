require 'rails_helper'

RSpec.describe QueueSession, type: :model do
  let(:venue) { Venue.create!(name: 'Test Venue') }

  describe 'associations' do
    it 'belongs to venue' do
      association = QueueSession.reflect_on_association(:venue)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'has many queue_items' do
      association = QueueSession.reflect_on_association(:queue_items)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'validates presence of venue' do
      session = QueueSession.new
      expect(session).not_to be_valid
      expect(session.errors[:venue]).to include("must exist")
    end

    it 'is valid with venue' do
      session = QueueSession.new(venue: venue)
      expect(session).to be_valid
    end
  end

  describe 'scopes' do
    it 'has active scope' do
      active_session = QueueSession.create!(venue: venue, is_active: true)
      inactive_session = QueueSession.create!(venue: venue, is_active: false)
      
      expect(QueueSession.active).to include(active_session)
      expect(QueueSession.active).not_to include(inactive_session)
    end
  end

  describe 'creation' do
    it 'defaults is_active to true' do
      session = QueueSession.create!(venue: venue)
      expect(session.is_active).to be true
    end
  end
end
