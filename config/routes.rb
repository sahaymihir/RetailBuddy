Rails.application.routes.draw do
  get "billing/new"
  root "pages#index"
  get "success", to: "pages#success", as: :success_path

  post "login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get '/products/search', to: 'products#search', as: 'search_products'

  resources :invoices, only: [:create, :show]
  resources :products
  resources :categories
  get '/inventory', to: 'inventory#index', as: 'inventory'

  resources :billing
  get "billing", to: "billing#new", as: :new_billing_path

  get '/reports', to: 'reports#index', as: 'reports'
  resources :customers
  get '/help', to: 'help#index', as: 'help'

  namespace :admin do
    resources :users
  end
end
