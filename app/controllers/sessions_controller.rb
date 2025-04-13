# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    # Assuming the login form submits email via 'user_id' key based on previous context
    submitted_email = params[:email]
    user = nil

    if submitted_email.present?
      # Find user by downcased email for case-insensitive matching
      user = User.find_by(email: submitted_email.downcase)
    end
    
    if user
      puts "DEBUG: Found user: #{user.userid}, Email: #{user.email}" # Confirm user found
      # --->>> ADD THIS LINE: <<<---
      puts "DEBUG: Comparing DB password: '#{user.password}' with submitted password: '#{params[:password]}'"
    else
      puts "DEBUG: User not found with email: #{submitted_email}" # Should not hit this now
    end

    # --- Changed authentication to plain text comparison ---
    if user && user.password == params[:password]
      # --- Login logic (remains the same) ---
      if params[:admin] == "true"
        if user.role == "Admin"
          session[:user_id] = user.userid
          session[:role] = user.role
          flash[:notice] = "Admin login successful"
          redirect_to success_path_url # Or admin_dashboard_path
        else
          flash[:alert] = "You do not have administrative privileges."
          redirect_to root_path # Or login_path
        end
      else # Standard login attempt
        session[:user_id] = user.userid
        session[:role] = user.role
        flash[:notice] = "Login successful"
        redirect_to success_path_url
      end
    else
      # Authentication failed
      flash[:alert] = "Invalid email or password."
      # Redirect back to the referring page or root path
      redirect_back(fallback_location: root_path)
    end
  end

  def destroy
    reset_session # Clears all session data
    flash[:notice] = 'Successfully logged out.'
    # Redirect to login page (root_path) with appropriate status
    redirect_to root_path, status: :see_other
  end
end