Rails.application.routes.draw do
  # login / landing
  root "login#index"
  get "/login", to: "login#index" # 別名（可選）

  # auth
  post   "/session", to: "sessions#create",  as: :session
  delete "/logout",  to: "sessions#destroy", as: :logout

  # app pages
  get "/mainpage", to: "main#index",  as: :mainpage
  get "/scan",     to: "scan#index",  as: :scan
  get "/search",   to: "search#index", as: :search
  get "/profile",  to: "profiles#show", as: :profile
end
