# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # --- Add Pagy Backend ---
  include Pagy::Backend
  # -----------------------

  helper_method :current_user, :admin?

  def current_user
    # Use find_by to avoid raising an error if session[:user_id] is nil or invalid
    @current_user ||= User.find_by(userid: session[:user_id]) if session[:user_id]
  end

  # Consider making admin? check the user role directly for consistency
  def admin?
    # current_user&.role == "Admin" # Safer check
    session[:role] == "Admin" # Current implementation from file
  end

  # This require_admin method looks correct for use in controllers
  def require_admin
    unless admin?
      flash[:alert] = "Unauthorized access!"
      redirect_to root_path
    end
  end

  def require_login
    unless current_user
      flash[:alert] = "You need to login to access this page."
      redirect_to root_path # Or your login path
    end
  end

  # Logout method - Note: The actual logout logic is likely in SessionsController#destroy

  before_action :set_cache_headers

  private

  def set_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
  end
end