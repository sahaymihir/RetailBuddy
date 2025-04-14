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
      # Ensure inventory gets default values if not provided
      inventory = @product.inventory || @product.build_inventory
      inventory.warehouse_location ||= 'Default Location' # Example default
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

    # Use the actual database column name 'product_name' for searching and ordering
    # Eager load inventory and category for potentially faster access (though not strictly needed for the response here)
    products_query = Product.includes(:inventory, :category)
                            .order(Arel.sql("LOWER(product_name)")) # Order by lowercase actual column

    if query.present?
      # Search against the actual database column 'product_name'
      products = products_query.where("LOWER(product_name) LIKE ?", "%#{query.downcase}%").limit(limit)
    else
      # Show recent products or top sellers if query is empty
      products = products_query.order(created_at: :desc).limit(5) # Example: Show 5 most recent
    end

    # Prepare JSON response
    products_json = products.map do |product|
      {
        id: product.id,
        product_name: product.product_name,
        price: product.price,
        stock_quantity: product.stock_quantity || 0,
        # Add the applicable tax rate here
        tax_rate: product.applicable_tax_rate || 0.0 # Ensure you handle nil case
      }
    end

    render json: { products: products_json }
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
      :product_name, # Use actual column name
      :price,
      :stock_quantity,
      :category_id,
      # Allow inventory attributes, ensure :id is present for updates
      inventory_attributes: [:id, :warehouse_location, :reorder_level, :_destroy] # Removed :quantity
    )
  end

  # Placeholder for login check
  # def require_login
  #   # ... your logic here, e.g., check session[:user_id]
  #   unless session[:user_id]
  #     flash[:alert] = "You must be logged in to access this section."
  #     redirect_to root_path # Or your login path
  #   end
  # end
end