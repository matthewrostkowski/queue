Rails.application.routes.draw do
  # Prevent /favicon.ico from failing scenarios
  get "/favicon.ico", to: ->(_env) { [204, { "Content-Type" => "image/x-icon" }, []] }

  # Root route
  root "songs#search"

  # Songs/Search
  get "/search", to: "songs#search"
  get "/songs", to: "songs#index"
  get "/songs/:id", to: "songs#show"

  # Queue Items (voting on individual items)
  resources :queue_items, only: [:index, :create, :show, :destroy] do
    member do
      post :upvote
      post :downvote
    end
  end

  # Queue/Playback (main queue controller)
  resource :queue, only: [:show], controller: 'queues' do
    post :start_playback
    post :next_track
    post :stop_playback
    get :state
  end

  # User authentication
  get    "/profile", to: "users#show", as: "profile"
  delete "/logout",  to: "sessions#destroy", as: "logout"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end