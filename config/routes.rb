Rails.application.routes.draw do
  get '/admin' => 'admin/dashboard#index', as: :admin
  namespace :admin do
    resources :statuses, only: [:index, :show, :destroy]
    resources :accounts, only: [:index]
    resources :users, except: [:new, :create]
  end
  require 'sidekiq/web'
  require 'admin_constraint'
  mount Sidekiq::Web => '/sidekiq', :constraints => AdminConstraint.new

  resources :users
  resources :accounts, only: [:index, :show, :edit, :update] do
    member do
      post :follow
    end
  end
  constraints(username_with_domain: /[^\/]+/) do
    get '/@:username_with_domain', to: 'accounts#show', as: :social_account
  end
  resources :statuses, only: [:index, :show, :create] do
    member do
      post :boost
      post :unboost
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
  get '/.well-known/nodeinfo' => 'well_known/nodeinfo#index', as: :nodeinfo
  get '/nodeinfo/2.0' => 'well_known/nodeinfo#show', as: :nodeinfo_schema
  get '/actor/:id' => 'users#actor', as: :actor, id: /[^\/]+/
  post '/actor/:id/inbox' => 'accounts#inbox', as: :inbox, id: /[^\/]+/
  get '/actor/:id/outbox' => 'accounts#outbox', as: :outbox, id: /[^\/]+/
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
