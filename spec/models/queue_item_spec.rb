require 'rails_helper'

RSpec.describe QueueItem, type: :model do
  let(:venue) { Venue.create!(name: 'V') }
  let(:qs)    { QueueSession.create!(venue: venue, is_active: true) }
  let(:user)  { User.create!(display_name: 'U', auth_provider: 'guest') }
  let(:song)  { Song.create!(title: 'Song', artist: 'Artist') }

  it 'computes price_for_display rising with demand and votes' do
    qi = QueueItem.create!(song: song, queue_session: qs, user: user, base_price: 2.00)
    expect(qi.price_for_display).to eq(2.00)
    QueueItem.create!(song: song, queue_session: qs, user: user, base_price: 2.00)
    qi.reload
    expect(qi.price_for_display).to be > 2.00
    qi.vote!(1)
    expect(qi.price_for_display).to be > 2.10
  end
end
