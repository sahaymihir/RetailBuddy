class SessionsController < ApplicationController
  def create
    # Example: Just redirect to admin dashboard for now
    redirect_to '/admin_login.html'
  end
end
