# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  before_action :require_login
  before_action :set_categories, only: [ :new, :create, :edit, :update ]
  before_action :set_product, only: [ :edit, :update, :destroy ] # No :show

  # GET /products/new
  def new
    @product = Product.new
    @product.build_inventory
  end

  # POST /products
  def create
    @product = Product.new(product_params)

    if @product.save
      # Ensure inventory gets default values if not provided
      inventory = @product.inventory || @product.build_inventory
      inventory.warehouse_location ||= "Default Location" # Example default
      inventory.reorder_level ||= 10                   # Example default
      inventory.save # Save inventory if it was just built

      redirect_to inventory_path, notice: "Product was successfully created."
    else
      # Ensure categories are set again for rendering the form
      set_categories
      render :new, status: :unprocessable_entity
    end
  end

  # GET /products/:id/edit
  def edit
    @product.build_inventory if @product.inventory.nil?
  end

  # PATCH/PUT /products/:id
  def update
    if @product.update(product_params)
      redirect_to inventory_path, notice: "Product was successfully updated."
    else
      # Ensure categories are set again for rendering the form
      set_categories
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    # Destroy associated inventory first if dependent: :destroy isn't reliable or sufficient
    # @product.inventory.destroy if @product.inventory
    @product.destroy # dependent: :destroy on has_one should handle inventory
    redirect_to inventory_path, notice: "Product was successfully deleted.", status: :see_other
  rescue ActiveRecord::RecordNotFound
     redirect_to inventory_path, alert: "Product not found."
  rescue StandardError => e
     # Catch other potential errors during destroy
     redirect_to inventory_path, alert: "Failed to delete product: #{e.message}"
  end

  # Search method - CORRECTED
  def search
    query = params[:q].presence || ""
    limit = 25

    # Use includes for efficiency
    products_query = Product.includes(:category, :inventory)
                            .order(Arel.sql("LOWER(product_name)"))

    if query.present?
      products = products_query.where("product_name LIKE ?", "%#{query}%").limit(limit)
    else
      products = products_query.order(created_at: :desc).limit(5)
    end

    # Prepare JSON response
    products_json = products.map do |product|
      product_category = product.category
      tax_rate = product_category&.tax_percentage || 0.0

      {
        id: product.id,
        product_name: product.product_name,
        price: product.price,
        stock_quantity: product.stock_quantity || 0, 
        tax_rate: tax_rate
      }
    end

    render json: { products: products_json }

  # Add a rescue block to catch potential errors during search
  rescue => e
    Rails.logger.error("Error in ProductsController#search: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    # Return an empty list or an error message in JSON format
    render json: { products: [], error: "Failed to search products: #{e.message}" }, status: :internal_server_error
  end
  
  private

  def set_product
    # Ensure inventory is included when finding a single product for edit/update/destroy
    @product = Product.includes(:inventory).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to inventory_path, alert: "Product not found."
  end

  def set_categories
    # Use actual column name for ordering
    @categories ||= Category.order(:category_name)
  end

  def product_params
    params.require(:product).permit(
      :name, # Use actual column name
      :price,
      :stock_quantity,
      :category_id,
      # Allow inventory attributes, ensure :id is present for updates
      inventory_attributes: [ :id, :warehouse_location, :reorder_level, :_destroy ] # Removed :quantity
    )
  end
end
