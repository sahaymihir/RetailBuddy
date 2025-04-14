Rails.application.routes.draw do
  get "billing/new"
  # Define the root route
  root "pages#index"

  # Define the success page route
  get "success", to: "pages#success", as: :success_path

  # Login routes
  post "login", to: "sessions#create"

  # Logout route (add explicit route name)
  delete "/logout", to: "sessions#destroy", as: :logout
  
  resources :products 
  resources :categories
  get '/inventory', to: 'inventory#index', as: 'inventory'
  
  resources :billing
  get "billing", to: "billing#new", as: :new_billing_path

  get '/reports', to: 'reports#index', as: 'reports'

  resources :customers

  get '/help', to: 'help#index', as: 'help'

  namespace :admin do
    # Creates routes like /admin/users, /admin/users/new, /admin/users/:id/edit etc.
    resources :users # index, new, create, edit, update, destroy, show (optional)
    # You might want a root for the admin section itself later
    # root to: "dashboard#index", as: :dashboard # Example
  end
end
