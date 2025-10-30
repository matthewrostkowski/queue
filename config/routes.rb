Rails.application.routes.draw do
  # Prevent /favicon.ico from failing scenarios
  get "/favicon.ico", to: ->(_env) { [204, { "Content-Type" => "image/x-icon" }, []] }

  # login / landing
  get  "/login", to: "login#index", as: :login
  root to: redirect("/login")

  # auth
  post   "/session", to: "sessions#create",  as: :session
  delete "/logout",  to: "sessions#destroy", as: :logout

  # app pages
  get "/mainpage", to: "main#index",  as: :mainpage
  get "/scan",     to: "scan#index",  as: :scan
  get "/search",   to: "search#index", as: :search
  get "/profile",  to: "profiles#show", as: :profile

  get  "/signup", to: "users#new",    as: :signup
  post "/users",  to: "users#create", as: :users
  get  "/users/:id/summary", to: "users#summary", as: :user_summary
  
  # Songs/Search (from PR #8)
  get "/songs", to: "songs#index"
  get "/songs/:id", to: "songs#show"

  # Queue Items (from PR #8)
  resources :queue_items, only: [:index, :create, :show, :destroy] do
    member do
      post :upvote
      post :downvote
    end
  end

  # Queue/Live View (from PR #8)
  get  "/queue",                to: "queues#show"
  post "/queue/start_playback", to: "queues#start_playback"
  post "/queue/next_track",     to: "queues#next_track"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
