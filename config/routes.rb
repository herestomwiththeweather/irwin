Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  resources :users
  resources :accounts, only: [:index, :show, :edit, :update] do
    member do
      post :follow
    end
  end
  resources :statuses, only: [:index, :show, :create] do
    member do
      post :boost
      get :replies
      get :translate
    end
    collection do
      get :private_mentions
      get :mentions
    end
  end
  resources :follows, only: [:destroy]
  resources :likes, only: [:create, :index, :destroy] do
    collection do
      get :received
    end
  end
  resources :sessions
  resources :searches, only: [:new, :create]
  resources :authorizations, only: [:index, :show]
  resources :access_tokens, only: [:destroy]

  namespace :api do
    namespace :v1 do
      namespace :timelines do
        resource :public, only: [:show], controller: :public
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  #
  get '/following' => 'accounts#following', as: :following
  get '/followers' => 'accounts#followers', as: :followers

  get '/.well-known/webfinger' => 'users#webfinger', as: :webfinger
  get '/actor/:id' => 'users#actor', as: :actor, id: /[^\/]+/
  post '/actor/:id/inbox' => 'accounts#inbox', as: :inbox, id: /[^\/]+/
  get '/actor/:id/followers' => 'users#followers', as: :api_followers, id: /[^\/]+/
  get '/actor/:id/following' => 'users#following', as: :api_following, id: /[^\/]+/

  get '/activities/:id' => 'users#activity', as: :activity

  get '/token' => 'access_tokens#validate', as: :validate
  post '/token' => 'access_tokens#create', as: :token
  # Defines the root path route ("/")
  # root "articles#index"
  resources :authorizations, only: :create
  get '/auth' => 'authorizations#new', as: :auth
  post '/auth' => 'access_tokens#profile_url', as: :profile_url
  get '/signup' => 'users#new', as: :signup
  get '/login' => 'sessions#new', as: :login
  get '/logout' => 'sessions#destroy', as: :logout
  root 'statuses#index'
end
