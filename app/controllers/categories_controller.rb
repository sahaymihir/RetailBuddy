# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  before_action :require_login
  # Add admin check if needed: before_action :require_admin
  before_action :set_category, only: [ :edit, :update, :destroy ] # Add :show if you need a show page

  # GET /categories
  def index
    @categories = Category.order(:category_name)
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
      render :new, status: :unprocessable_entity
    end
  end

  # GET /categories/:id/edit
  def edit
    # @category set by before_action
  end

  # PATCH/PUT /categories/:id
  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /categories/:id
  def destroy
    # Add check if category has associated products before deleting?
    if @category.products.exists?
       redirect_to categories_path, alert: "Cannot delete category with associated products."
    else
       @category.destroy
       redirect_to categories_path, notice: "Category was successfully deleted.", status: :see_other
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  rescue ActiveRecord::RecordNotFound
     redirect_to categories_path, alert: "Category not found."
  end

  def category_params
    params.require(:category).permit(:category_name, :description)
  end
end
