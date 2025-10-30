Rails.application.routes.draw do
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
  
  # queue management
  post "/queue_items", to: "queue_items#create", as: :queue_items

  # Queue items JSON API
  resources :queue_items, only: [:index, :create] do
    member do
      patch :vote   # /queue_items/:id/vote
    end
  end

  get "songs/search", to: "songs#search"
  resources :venues, only: [:show]
end
