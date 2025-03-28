Rails.application.routes.draw do
  # Define the root route
  root "pages#index"

  # Define the success page route
  get "success", to: "pages#success", as: :success_path

  # Login routes
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
end
