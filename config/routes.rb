Rails.application.routes.draw do
  resources :users
  resources :sessions
  resources :access_tokens, only: [:index, :show, :destroy]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get '/token' => 'access_tokens#validate', as: :validate
  post '/token' => 'access_tokens#create', as: :token
  # Defines the root path route ("/")
  # root "articles#index"
  resources :authorizations, only: :create
  get '/auth' => 'authorizations#new', as: :auth
  get '/signup' => 'users#new', as: :signup
  get '/login' => 'sessions#new', as: :login
  get '/logout' => 'sessions#destroy', as: :logout
  root 'sessions#home'
end
