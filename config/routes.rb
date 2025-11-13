Rails.application.routes.draw do
  # Login page
  get  "/login", to: "login#index", as: :login
  root to: redirect("/login")

  # Prevent /favicon.ico from failing scenarios
  get "/favicon.ico", to: ->(_env) { [204, { "Content-Type" => "image/x-icon" }, []] }

  # Songs/Search
  get "/search",        to: "songs#search"
  get "/songs",         to: "songs#index"
  get "/songs/search",  to: "songs#search"
  get "/songs/:id",     to: "songs#show"

  # User signup and summary
  get  "/signup", to: "users#new",    as: :signup
  post "/users",  to: "users#create", as: :users
  get  "/users/:id/summary", to: "users#summary", as: :user_summary

  # User authentication
  get    "/profile", to: "profiles#show", as: "profile"
  delete "/logout",  to: "sessions#destroy", as: "logout"
  post   "/session", to: "sessions#create",  as: :session

  # Main page
  get  "/mainpage", to: "main#index", as: :mainpage

  # Scan / join-by-code
  get  "/scan", to: "scan#index", as: :scan
  post "/scan", to: "scan#join_by_code"           # backwards compatible
  post "/join", to: "scan#join_by_code", as: :join

  # google oauth2 callback
  get "/auth/:provider/callback", to: "sessions#omniauth"
  get "/auth/failure",            to: redirect("/login")

  # Queue Items (voting on individual items)
  resources :queue_items, only: [:index, :create, :show, :destroy] do
    member do
      patch :vote
      post  :upvote
      post  :downvote
    end
  end

  # Queue/Playback (main queue controller)
  resource :queue, only: [:show], controller: "queues" do
    post :start_playback
    post :next_track
    post :stop_playback
    get  :state
  end

  # Admin
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :users, only: [:index] do
      member do
        patch :promote_to_host
        patch :promote_to_admin
        patch :demote
      end
    end
  end

  # Public Venues
  resources :venues, only: [:show]

  # Host namespace (host side of the product)
  namespace :host do
    resources :venues do
      member do
        get  :dashboard
        post :create_session
        post :start_session
        patch :pause_session
        patch :resume_session
        patch :end_session
        patch :regenerate_code
      end
    end

    resources :queue_sessions, only: [] do
      member do
        patch :pause
        patch :resume
        patch :end
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
