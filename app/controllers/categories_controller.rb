# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  # Ensure user is logged in for all actions
  before_action :require_login # Assuming you have this method in ApplicationController

  # Ensure only admins can manage categories (create, update, delete)
  # You might want to exclude :index and :show if regular users can view categories
  before_action :require_admin, only: [:new, :create, :edit, :update, :destroy]

  # Find the specific category for relevant actions
  before_action :set_category, only: [:show, :edit, :update, :destroy] # Added :show assuming you might have a show view

  # GET /categories
  def index
    # Fetch categories, order by name
    @categories = Category.order(:name)
  end

  # GET /categories/1 (Optional show action)
  def show
    # @category is set by before_action
    # Render show view (e.g., app/views/categories/show.html.erb)
  end


  # GET /categories/new
  def new
    @category = Category.new
  end

  # POST /categories
  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Category was successfully created."
    else
      # Validation failed, re-render the form with errors
      render :new, status: :unprocessable_entity
    end
  end

  # GET /categories/:id/edit
  def edit
    # @category is set by before_action
  end

  # PATCH/PUT /categories/:id
  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category was successfully updated."
    else
      # Validation failed, re-render the form with errors
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /categories/:id
  def destroy
    # Attempt to destroy the category.
    # Relies on `dependent: :restrict_with_error` in the Category model
    # to prevent deletion if products are associated.
    if @category.destroy
       redirect_to categories_path, notice: "Category was successfully deleted.", status: :see_other
    else
       # Deletion failed, likely due to associated products. The error message
       # comes from the model validation.
       redirect_to categories_path, alert: "Cannot delete category: #{@category.errors.full_messages.join(', ')}", status: :unprocessable_entity
    end
  end

  private

  # Find category by ID from parameters
  def set_category
    @category = Category.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # Handle case where category ID is invalid
    redirect_to categories_path, alert: "Category not found."
  end

  # Define strong parameters allowed for category creation/updates
  def category_params
    # Permit :name and the new :tax_percentage field.
    # Removed :description as it wasn't in the model definition provided earlier.
    # Removed :category_name, using :name instead for consistency.
    params.require(:category).permit(:name, :tax_percentage)
  end

  # Placeholder for admin authorization check
  def require_admin
    # Replace this with your actual authorization logic.
    # Example: Check if current_user has an 'admin' role.
    # unless current_user&.admin? # Assuming a boolean 'admin?' method on User model
    #   redirect_to root_path, alert: "You are not authorized to perform this action."
    # end

    # For now, let's assume it passes to avoid blocking development.
    # In production, this MUST be implemented correctly.
    true
  end

  # Assuming require_login is defined in ApplicationController
  # def require_login
  #   unless logged_in? # Example check
  #     redirect_to login_path, alert: "You must be logged in to access this section."
  #   end
  # end

end