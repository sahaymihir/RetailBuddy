# app/controllers/billing_controller.rb
class BillingController < ApplicationController
  before_action :require_login
  # If rendering full HTML page:
  layout false

  # GET /billing/new (or GET /billing) - Renders the main billing interface
  def new
    @products = Product.includes(:inventory, :category)
                       .order(:product_name)
                       .limit(5)

    @customers = Customer.order(:name) # Use Arel.sql with uppercase column

    # Placeholder for items added to the current bill in the view
    @bill_items = []
  end

  # Add other actions like :show, :edit, :update, :destroy if needed for past bills
end
