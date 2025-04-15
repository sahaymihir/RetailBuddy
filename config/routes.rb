Rails.application.routes.draw do
  get "billing/new"
  root "pages#index"
  get "success", to: "pages#success", as: :success_path

  post "login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get '/products/search', to: 'products#search', as: 'search_products'

  resources :invoices, only: [:index, :create, :show] do # Now includes index
    get 'printable', on: :member
  end
  
  resources :products
  resources :categories
  get '/inventory', to: 'inventory#index', as: 'inventory'

  resources :billing
  get "billing", to: "billing#new", as: :new_billing_path

  get '/reports', to: 'reports#index', as: 'reports'
  get 'reports/todays_sales', to: 'reports#todays_sales', as: 'todays_sales_report'
  get 'reports/sales_by_period', to: 'reports#sales_by_period', as: 'sales_by_period_report'
  get 'reports/top_products', to: 'reports#top_products', as: 'top_products_report'
  get 'reports/sales_by_category', to: 'reports#sales_by_category', as: 'sales_by_category_report'
  get 'reports/top_customers', to: 'reports#top_customers', as: 'top_customers_report'
  resources :customers
  get '/help', to: 'help#index', as: 'help'

  namespace :admin do
    resources :users
  end
end
