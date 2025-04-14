# app/controllers/billing_controller.rb
class BillingController < ApplicationController
  before_action :require_login
  # If rendering full HTML page:
  layout false

  # GET /billing/new (or GET /billing) - Renders the main billing interface
  def new
    # Load products, explicitly ordering by the uppercase Oracle column name
    # Assumes product name column in Oracle is PRODUCT_NAME
    @products = Product.includes(:inventory, :category)
                       .order(Arel.sql("PRODUCT_NAME")) # Keep existing order
                       .limit(5)

    # Load customers, explicitly ordering by the uppercase Oracle column name
    # Assumes customer name column in Oracle is NAME
    @customers = Customer.order(Arel.sql("NAME")) # Use Arel.sql with uppercase column

    # Placeholder for items added to the current bill in the view
    @bill_items = []
  end

  # Add other actions like :show, :edit, :update, :destroy if needed for past bills
end
