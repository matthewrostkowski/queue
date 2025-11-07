require 'rails_helper'

RSpec.describe QueueItem, type: :model do
  it 'exists as a model' do
    expect(QueueItem).to be_a(Class)
  end

  it 'has a queue_session association' do
    expect(QueueItem.reflect_on_association(:queue_session)).to be_present
  end

  it 'has a song association' do
    expect(QueueItem.reflect_on_association(:song)).to be_present
  end
end
