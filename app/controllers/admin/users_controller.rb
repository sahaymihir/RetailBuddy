# app/controllers/admin/users_controller.rb
class Admin::UsersController < ApplicationController
  # Assuming Pagy is included in ApplicationController or elsewhere
  # Assuming require_admin is correctly implemented in ApplicationController
  before_action :require_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /admin/users
  def index
    @pagy, @users = pagy(User.order(:userid))
    # Retrieve new user details from flash if redirected after creation
    @new_user_details = flash[:new_user_details]
  end

  # GET /admin/users/:id
  def show
    # @user is set by before_action :set_user
    # Note: The view file 'show.html.erb' was not provided.
  end

  # GET /admin/users/new
  def new
    @user = User.new
  end

  # GET /admin/users/:id/edit
  def edit
    # @user is set by before_action :set_user
  end

  # POST /admin/users
  def create
    @user = User.new(user_params_for_create) # Use specific create params

    # Auto-generate email based on name and role
    if @user.name.present? && @user.role.present?
      domain_suffix = @user.role == 'Admin' ? 'admin.retailbuddy.com' : 'employee.retailbuddy.com'
      generated_email = "#{@user.name.parameterize}@#{domain_suffix}"
      @user.email = generated_email
    end

    if @user.save
      # Store details of the newly created user in flash to display on index
      redirect_to admin_users_path, notice: 'User was successfully created.'
    else
      # Re-render the form with errors if save fails
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/users/:id
  def update
    # Use specific update params
    if @user.update(user_params_for_update)
      redirect_to admin_user_path(@user.to_param), notice: 'User was successfully updated.'
    else
      # Re-render the form with errors if update fails
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/users/:id
  def destroy
    begin
      @user.destroy!
      redirect_to admin_users_path, notice: 'User was successfully deleted.', status: :see_other
    rescue ActiveRecord::RecordNotDestroyed => e
      Rails.logger.error("Admin::UsersController: Error destroying user ID: #{@user.userid} - #{e.message}")
      redirect_to admin_users_path, alert: "Failed to delete user: #{e.message}"
    rescue StandardError => e
       Rails.logger.error("Admin::UsersController: Unexpected error destroying user ID: #{@user.userid} - #{e.message}")
       redirect_to admin_users_path, alert: 'An unexpected error occurred while deleting the user.'
    end
  end

  private
    # Finds the user based on the 'userid' parameter
    def set_user
      @user = User.find_by(userid: params[:id])
      redirect_to admin_users_path, alert: 'User not found.' unless @user
    end

    # Strong parameters for creating a user (permits name, role, password)
    def user_params_for_create
      params.require(:user).permit(:name, :role, :password)
    end

    # Strong parameters for updating a user (permits name, role, password)
    # Note: Email is not permitted for update as it's auto-generated/fixed.
    # Password update is optional (leave blank to keep current).
    def user_params_for_update
      params.require(:user).permit(:name, :role, :password)
    end
end