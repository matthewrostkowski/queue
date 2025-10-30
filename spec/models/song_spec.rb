require 'rails_helper'

RSpec.describe Song, type: :model do
  describe 'associations' do
    it 'has many queue_items' do
      association = Song.reflect_on_association(:queue_items)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many users_who_queued through queue_items' do
      association = Song.reflect_on_association(:users_who_queued)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'validates presence of title' do
      song = Song.new(artist: 'Test Artist')
      expect(song).not_to be_valid
      expect(song.errors[:title]).to include("can't be blank")
    end

    it 'validates presence of artist' do
      song = Song.new(title: 'Test Song')
      expect(song).not_to be_valid
      expect(song.errors[:artist]).to include("can't be blank")
    end

    it 'is valid with title and artist' do
      song = Song.new(title: 'Test Song', artist: 'Test Artist')
      expect(song).to be_valid
    end
  end

  describe '#album_art' do
    it 'returns cover_url when present' do
      song = Song.new(title: 'Test', artist: 'Test', cover_url: 'http://example.com/cover.jpg')
      expect(song.album_art).to eq('http://example.com/cover.jpg')
    end

    it 'returns placeholder when cover_url is blank' do
      song = Song.new(title: 'Test Song', artist: 'Test')
      expect(song.album_art).to include('placeholder')
      expect(song.album_art).to include('T') # First letter of title
    end
  end

  describe 'methods' do
    it 'can be created and saved' do
      song = Song.create!(title: 'Test Song', artist: 'Test Artist')
      expect(song.title).to eq('Test Song')
      expect(song.artist).to eq('Test Artist')
    end
  end
end
