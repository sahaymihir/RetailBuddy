# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  before_action :require_login
  before_action :set_categories, only: [:new, :create, :edit, :update]
  before_action :set_product, only: [:edit, :update, :destroy] # No :show

  # GET /products/new
  def new
    @product = Product.new
    # Build associated inventory record for the form
    @product.build_inventory
  end

  # POST /products
  def create
    @product = Product.new(product_params) # Params now include inventory attributes

    if @product.save # Saving the product will now also save the associated inventory
      redirect_to inventory_path, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /products/:id/edit
  def edit
    # Ensure inventory exists for editing, build if missing
    @product.build_inventory if @product.inventory.nil?
  end

  # PATCH/PUT /products/:id
  def update
    if @product.update(product_params) # Updating product also updates inventory
       redirect_to inventory_path, notice: "Product was successfully updated."
    else
       render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    # Transaction no longer strictly needed here as dependent: :destroy handles inventory
    begin
      # dependent: :destroy in model will handle inventory deletion
      @product.destroy!
      redirect_to inventory_path, notice: "Product was successfully deleted.", status: :see_other
    rescue => e
      redirect_to inventory_path, alert: "Failed to delete product: #{e.message}"
    end
  end

  private

  def set_product
    # Include inventory when finding for edit/update forms
    @product = Product.includes(:inventory).find(params[:id])
  rescue ActiveRecord::RecordNotFound
     redirect_to inventory_path, alert: "Product not found."
  end

  def set_categories
    @categories = Category.order(:category_name)
  end

  # Update product_params to accept nested attributes for inventory
  def product_params
    params.require(:product).permit(
      :product_name,
      :price,
      :stock_quantity,
      :category_id,
      # Permit nested inventory attributes: :id and :_destroy allow management via nested forms
      inventory_attributes: [:id, :warehouse_location, :reorder_level, :_destroy]
    )
  end
end