require 'rails_helper'

RSpec.describe QueuesController, type: :controller do
  it 'exists as a controller' do
    expect(QueuesController).to be_a(Class)
  end

  it 'has a show action defined' do
    expect(QueuesController.instance_methods).to include(:show)
  end

  it 'has a state action defined' do
    expect(QueuesController.instance_methods).to include(:state)
  end
end
