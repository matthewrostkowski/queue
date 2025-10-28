Rails.application.routes.draw do
  # login / landing
  root "home#index"
  get "/login", to: "home#index" # 別名（可選）

  # auth
  post   "/session", to: "sessions#create",  as: :session
  delete "/logout",  to: "sessions#destroy", as: :logout

  # app pages
  get "/mainpage", to: "main#index",  as: :mainpage
  get "/scan",     to: "scan#index",  as: :scan
  get "/search",   to: "search#index", as: :search
end
