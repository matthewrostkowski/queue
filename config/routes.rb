Rails.application.routes.draw do

  get  "/login", to: "login#index", as: :login
  root to: redirect("/login")
  # Prevent /favicon.ico from failing scenarios
  get "/favicon.ico", to: ->(_env) { [204, { "Content-Type" => "image/x-icon" }, []] }

  # Root route
  #root "songs#search"

  # Songs/Search
  get "/search", to: "songs#search"
  get "/songs", to: "songs#index"
  get "/songs/search", to: "songs#search"
  get "/songs/:id", to: "songs#show"

  # User signup and summary
  get  "/signup", to: "users#new",    as: :signup
  post "/users",  to: "users#create", as: :users
  get  "/users/:id/summary", to: "users#summary", as: :user_summary
  
  # User authentication
  get    "/profile", to: "profiles#show", as: "profile"
  delete "/logout",  to: "sessions#destroy", as: "logout"

  # Session management
  post "/session", to: "sessions#create", as: :session
  
  
  # Main page
  get  "/mainpage", to: "main#index", as: :mainpage
  
  # Scan route
  get  "/scan", to: "scan#index", as: :scan
  post "/scan", to: "scan#create"

  # Queue Items (voting on individual items)
  resources :queue_items, only: [:index, :create, :show, :destroy] do
    member do
      patch :vote      # For general vote endpoint
      post :upvote     # For upvote endpoint
      post :downvote   # For downvote endpoint
    end
  end

  # Queue/Playback (main queue controller)
  resource :queue, only: [:show], controller: 'queues' do
    post :start_playback
    post :next_track
    post :stop_playback
    get :state
  end

  # Venues
  resources :venues, only: [:show]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
