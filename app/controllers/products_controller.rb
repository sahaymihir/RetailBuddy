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

  # Search method
  def search
    query = params[:q].presence || ""
    limit = 25
  
    products_query = Product.includes(:inventory)
                            .order(Arel.sql("PRODUCT_NAME"))
  
    if query.present?
      products = products_query.where("UPPER(PRODUCT_NAME) LIKE ?", "%#{query.upcase}%").limit(limit)
    else
      products = products_query.limit(5)
    end
  
    # Render HTML response and ensure correct content type
    render json: { products: products.as_json(only: [:id, :product_name, :price, :stock_quantity]) }
  end

  def show
    # Leave empty if you don't have a show page
  end

  private

  def set_product
    @product = Product.includes(:inventory).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to inventory_path, alert: "Product not found."
  end

  def set_categories
    @categories = Category.order(:category_name)
  end

  def product_params
    params.require(:product).permit(
      :product_name,
      :price,
      :stock_quantity,
      :category_id,
      inventory_attributes: [:id, :warehouse_location, :reorder_level, :_destroy]
    )
  end
end
