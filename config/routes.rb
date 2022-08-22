Rails.application.routes.draw do
  resources :users
  resources :sessions
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :authorizations, only: :create
  get '/auth' => 'authorizations#new', as: :auth

  get '/logout' => 'sessions#destroy', as: :logout
  root 'sessions#home'
end
