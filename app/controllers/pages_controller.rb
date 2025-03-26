class PagesController < ApplicationController
  layout false
  before_action :require_login, only: [:success]
  def index
    # Home page logic (if any)
  end

  def success
    @total_sales_revenue = Invoice.where(status: :paid).sum(&:calculated_total_amount)
    @total_transactions = Invoice.where(id: Invoice.select(:id).where(status: :paid)).count
    # Fetch a maximum of 2 products where stock is at or below reorder level
    @low_stock_items = Product.joins(:inventory)
                              .where("products.stock_quantity <= inventories.reorder_level")
                              .includes(:category)
                              .limit(2) 

    # @current_user is available due to before_action :require_login
  end
end