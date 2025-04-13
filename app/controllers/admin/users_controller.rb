# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < ApplicationController
    before_action :require_admin
    layout false
    before_action :set_user, only: [:edit, :update, :destroy] # Keep this if needed

    # GET /admin/users
    def index
      # --- FIX: Load actual users ---
      @users = User.all.order(:userid) # Or apply pagination/sorting as needed
      # --- END FIX ---
    end

    # GET /admin/users/new
    def new
      @user = User.new # Initialize for the form
    end

    # POST /admin/users
    def create
      @user = User.new(user_params)
      # Add logic to handle password/password_digest based on your User model setup
      # Example using plain password field (adjust if using password_digest/has_secure_password):
      # @user.password = params[:user][:password] if params[:user][:password].present?

      if @user.save
        redirect_to admin_users_path, notice: "User created successfully."
      else
         flash.now[:alert] = "Failed to create user."
         render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/users/:id/edit
    def edit
      # User is set by before_action :set_user
      # Render the edit form (app/views/admin/users/edit.html.erb)
       unless @user # Add check in case set_user failed
           redirect_to admin_users_path, alert: "User not found."
       end
    end

    # PATCH/PUT /admin/users/:id
    def update
      # User is set by before_action :set_user
      unless @user
        redirect_to admin_users_path, alert: "User not found."; return
      end

      # Handle password update - only update if a new password is provided
      if params[:user][:password].present?
        if params[:user][:password] == params[:user][:password_confirmation]
          # Adjust this based on whether you use `password=` or `update` with has_secure_password
           if @user.update(password: params[:user][:password]) # Example for plain password
             redirect_to admin_users_path, notice: "User password updated successfully."
           else
             flash.now[:alert] = "Password could not be updated."
             render :edit, status: :unprocessable_entity
           end
        else
          @user.errors.add(:password_confirmation, "doesn't match Password")
          flash.now[:alert] = "Password confirmation doesn't match."
          render :edit, status: :unprocessable_entity
        end
      else
        # No password provided, perhaps update other attributes if needed?
        # Or just indicate no password change was attempted.
        redirect_to admin_users_path, notice: "No password change requested."
      end
    end

    # DELETE /admin/users/:id
    def destroy
       unless @user
        redirect_to admin_users_path, alert: "User not found."; return
      end
      # User is set by before_action :set_user
      begin
        @user.destroy!
        redirect_to admin_users_path, notice: "User deleted successfully.", status: :see_other
      rescue => e
        redirect_to admin_users_path, alert: "Failed to delete user: #{e.message}"
      end
    end


    private

    def set_user
      @user = User.find_by(userid: params[:id]) # Use find_by to avoid exception
    end

    # Define permitted parameters - Use exact column names from DB/Model
    def user_params
      params.require(:user).permit(:name, :email, :role, :password, :password_confirmation)
    end

     def require_admin
       unless current_user && current_user.role == "Admin"
         flash[:alert] = "Unauthorized access!"
         redirect_to root_path
       end
     end
  end
end