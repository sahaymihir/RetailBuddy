Rails.application.routes.draw do
  # Set root to the index page
  root to: redirect('/index.html')

  # Admin Login Page - Make Sure It Doesn't Auto-Redirect
  get '/admin', to: redirect('/admin_login.html')

  # Handle login request
  post '/login', to: 'sessions#create'
end
