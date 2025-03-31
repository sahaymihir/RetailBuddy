class ApplicationController < ActionController::Base
  helper_method :current_user, :admin?

  def current_user
    @current_user ||= User.find_by(userid: session[:user_id])
  end

  def admin?
    session[:role] == "Admin"
  end

  def require_admin
    unless admin?
      flash[:alert] = "Unauthorized access!"
      redirect_to root_path
    end
  end

  # Logout method
  before_action :set_cache_headers

  private

  def set_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
  end
end
