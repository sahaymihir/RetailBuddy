# app/controllers/invoices_controller.rb

class InvoicesController < ApplicationController
  # Skip CSRF token verification if necessary (ensure security elsewhere)
  # protect_from_forgery except: :create

  # Uncomment if login is required
  # before_action :require_login

  # POST /invoices
  def create
    permitted_params = invoice_params
    invoice_data = permitted_params

    invoice = nil
    error_message = nil

    ActiveRecord::Base.transaction do
      # 1. Find Customer (handle optional customer)
      customer = Customer.find_by(id: invoice_data[:customer_id]) if invoice_data[:customer_id].present?

      # 2. Initialize Invoice header
      invoice = Invoice.new(
        customer: customer,
        subtotal: invoice_data[:subtotal],      # Assign subtotal
        discount: invoice_data[:discount] || 0,
        tax: invoice_data[:tax] || 0,          # Assign tax
        total_amount: invoice_data[:grand_total],
        invoice_date: Time.current
      )

      # 3. Validate stock and prepare Invoice Lines
      items_data = invoice_data[:items] || []
      if items_data.empty?
        error_message = "Cannot finalize an empty bill."
        raise ActiveRecord::Rollback
      end

      items_data.each do |item_data|
        # Find Product
        unless item_data.key?(:product_id) && item_data[:product_id].present?
          error_message = "Missing product information for an item."
          raise ActiveRecord::Rollback
        end
        product = Product.find(item_data[:product_id])

        # Get and Validate Quantity
        unless item_data.key?(:quantity) && item_data[:quantity].present?
          error_message = "Missing quantity for product #{product.product_name}."
          raise ActiveRecord::Rollback
        end
        quantity = item_data[:quantity].to_i

        if quantity <= 0
          error_message = "Invalid quantity (#{quantity}) for #{product.product_name}."
          raise ActiveRecord::Rollback
        end

        # Perform Stock Check
        if quantity > product.stock_quantity
          error_message = "Insufficient stock for #{product.product_name}. Only #{product.stock_quantity} available."
          raise ActiveRecord::Rollback
        end

        # Build the line item - **REMOVED total_price**
        invoice.invoice_lines.build(
          product: product,
          quantity: quantity,
          unit_price: item_data[:price] # Store the unit price sent from frontend
          # Removed: total_price: item_data[:total]
        )
      end # End items loop

      # 4. Save Invoice and associated InvoiceLines
      invoice.user = current_user
      unless invoice.save
         error_message = "Failed to save invoice: #{invoice.errors.full_messages.join(', ')}"
         raise ActiveRecord::Rollback
      end

      # 5. Decrement Stock
      invoice.invoice_lines.each do |line|
         line.product.decrement!(:stock_quantity, line.quantity)
      end

      # 6. Create Payment Record
      payment = Payment.new(
         invoice: invoice,
         payment_method: invoice_data[:payment_method],
         payment_status: 'Completed',
         payment_date: Time.current
      )
      unless payment.save
          error_message = "Invoice saved, but failed to record payment: #{payment.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
      end

    rescue ActiveRecord::Rollback => e
      error_message ||= "An error occurred during finalization."
      invoice = nil
    rescue ActiveRecord::RecordNotFound => e
      error_message = "Could not find a product specified in the order."
      invoice = nil
    rescue StandardError => e
      Rails.logger.error("Invoice creation failed unexpectedly: #{e.message}\n#{e.backtrace.join("\n")}")
      error_message = "An unexpected server error occurred. Please contact support."
      invoice = nil
      raise ActiveRecord::Rollback unless error_message
    end # End Transaction

    # --- Respond to the frontend JavaScript ---
    if invoice
      render json: { success: true, invoice_id: invoice.id, message: "Invoice ##{invoice.id} created successfully." }, status: :created
    else
      render json: { success: false, message: error_message }, status: :unprocessable_entity
    end
  end

  # GET /invoices/:id
  def show
     @invoice = Invoice.includes(:customer, invoice_lines: :product).find(params[:id])
     render layout: "printable"
  rescue ActiveRecord::RecordNotFound
     redirect_to root_path, alert: "Invoice not found."
  end

  private

  # Strong parameters - REMOVED :total from items array
  def invoice_params
    params.require(:invoice).permit(
      :customer_id,
      :subtotal,
      :discount,
      :tax,
      :grand_total,
      :payment_method,
      items: [
        :product_id,
        :quantity,
        :price # Permit unit price
        # Removed :total
      ]
    )
  end
end
