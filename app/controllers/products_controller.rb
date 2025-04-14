# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  before_action :require_login
  before_action :set_categories, only: [:new, :create, :edit, :update]
  before_action :set_product, only: [:edit, :update, :destroy] # No :show

  # GET /products/new
  def new
    @product = Product.new
    @product.build_inventory
  end

  # POST /products
  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to inventory_path, notice: "Product was successfully created."
    else
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
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    begin
      @product.destroy!
      redirect_to inventory_path, notice: "Product was successfully deleted.", status: :see_other
    rescue => e
      redirect_to inventory_path, alert: "Failed to delete product: #{e.message}"
    end
  end

  # Search method - Minimal fixes applied
  def search
    query = params[:q].presence || ""
    limit = 25 # Keep original limit

    # Eager load inventory to get quantity
    products_query = Product.includes(:inventory)
                            .order(:name) # Order by the correct column name :name

    if query.present?
      # Use LOWER instead of UPPER for consistency and potential index usage
      products = products_query.where("LOWER(name) LIKE ?", "%#{query.downcase}%").limit(limit)
    else
      products = products_query.limit(5) # Keep original limit for empty query
    end

    # Prepare JSON response
    products_json = products.map do |product|
      {
        id: product.id,
        name: product.name, # Use :name
        price: product.price,
        inventory_quantity: product.inventory&.quantity || 0 # Get quantity from inventory
      }
    end

    render json: { products: products_json }
  end

  # Removed empty show action

  private

  def set_product
    @product = Product.includes(:inventory).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to inventory_path, alert: "Product not found."
  end

  def set_categories
    @categories = Category.order(:name) # Use :name instead of :category_name
  end

  def product_params
    params.require(:product).permit(
      :name, # Use :name instead of :product_name
      :price,
      :stock_quantity,
      :category_id,
      # Permit :quantity for inventory nested attributes
      inventory_attributes: [:id, :quantity, :warehouse_location, :reorder_level, :_destroy]
    )
  end

  # Placeholder for login check
  # def require_login
  #   # ... your logic
  # end
end