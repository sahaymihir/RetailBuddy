class SessionsController < ApplicationController
  def create
    user = User.find_by(userid: params[:user_id])

    if user && user.password == params[:password] # Validate credentials
      if params[:admin] == "true" # Admin login attempt
        if user.role == "Admin"
          session[:user_id] = user.userid
          session[:role] = user.role
          flash[:notice] = "Admin login successful"
          redirect_to success_path_url # Redirect to success page for admins
        else
          flash[:alert] = "Unauthorized access! Only Admins can log in here."
          redirect_to root_path # Redirect back to home page for unauthorized access
        end
      else # Employee login attempt
        session[:user_id] = user.userid
        session[:role] = user.role
        flash[:notice] = "Login successful"
        redirect_to success_path_url # Redirect to success page for employees
      end
    else
      flash[:alert] = "Invalid credentials"
      redirect_back(fallback_location: root_path) # Redirect back with error message
    end
  end
end
