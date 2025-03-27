Rails.application.routes.draw do
  root "pages#index"
  get "admin_login", to: "pages#admin_login"
end
