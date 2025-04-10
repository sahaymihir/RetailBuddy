# app/controllers/inventory_controller.rb
class InventoryController < ApplicationController
  before_action :require_login
  layout false

  def index
    # Start with a base scope including necessary associations
    @products = Product.includes(:category, :inventory) # [cite: 374]

    if params[:category_id].present?
      @products = @products.where(category_id: params[:category_id])
    end

    # Filter by Search Query if provided and not blank
    if params[:search_query].present?
      # Simple search on product_name - adjust column/logic as needed
      query_term = "%#{params[:search_query]}%"
      @products = @products.where("product_name LIKE :search", search: query_term)
    end
    # --- End Filters ---

    # Fetch all products after filtering
    @products = @products.all 

    # Load categories for the dropdown filter
    @categories = Category.all 
  end
end