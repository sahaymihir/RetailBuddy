# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  # Ensure authentication and authorization as needed, e.g.:
  # before_action :require_login
  # before_action :ensure_current_user_present # Example check

  # GET /invoices
  def index
    # Paginate for performance if you have many invoices
    # Eager load customer to avoid N+1 queries in the view
    @invoices = Invoice.includes(:customer).order(invoice_date: :desc)
                       .paginate(page: params[:page], per_page: 20) # Example pagination
  end

  # POST /invoices
  def create
    # 1. Separate invoice header params from line items and payment details
    invoice_data = invoice_params
    invoice_lines_data = invoice_data.delete(:invoice_lines_attributes) || []
    payment_method_value = invoice_data.delete(:payment_method)
    payment_status_value = invoice_data.delete(:payment_status) || 'Completed' # Default payment status

    # --- START STOCK VALIDATION ---
    insufficient_stock_items = []
    products_to_process = [] # Store products to avoid multiple lookups

    invoice_lines_data.each do |line_attrs|
      product = Product.find_by(id: line_attrs[:product_id])
      requested_quantity = line_attrs[:quantity].to_i

      if product && requested_quantity > 0
        products_to_process << { product: product, requested: requested_quantity, line_attrs: line_attrs }
        current_stock = product.stock_quantity || 0
        if requested_quantity > current_stock
          insufficient_stock_items << { name: product.name, requested: requested_quantity, available: current_stock }
        end
      elsif !product
         # Immediately return error if product ID is invalid
         render json: { success: false, message: "Invalid product ID #{line_attrs[:product_id]} provided." }, status: :unprocessable_entity
         return
      elsif requested_quantity <= 0
         # Immediately return error for invalid quantity
          render json: { success: false, message: "Invalid quantity (#{requested_quantity}) for product ID #{line_attrs[:product_id]}." }, status: :unprocessable_entity
          return
      end
    end

    # If any items have insufficient stock, return error
    unless insufficient_stock_items.empty?
      error_message = "Insufficient stock for: " + insufficient_stock_items.map { |item|
        "#{item[:name]} (Requested: #{item[:requested]}, Available: #{item[:available]})"
      }.join(', ')
      render json: { success: false, message: error_message }, status: :unprocessable_entity
      return
    end
    # --- END STOCK VALIDATION ---

    # 2. Ensure we have line items (Check after stock validation)
    if products_to_process.empty? # Use the validated list
      render json: { success: false, message: "Cannot create an invoice with no items." }, status: :unprocessable_entity
      return
    end

    # 3. Initialize Invoice
    @invoice = Invoice.new(invoice_data)
    @invoice.invoice_date ||= Time.current
    @invoice.status ||= :draft # Use enum symbol or integer (default is 'draft')

    # Assign current user (Ensure current_user method exists and works)
    if current_user
      @invoice.user_id = current_user.userid
    else
      Rails.logger.error("Cannot create invoice: current_user is nil.")
      render json: { success: false, message: "User session not found. Please log in again." }, status: :unauthorized
      return
    end

    # 4. Build invoice lines using validated data
    products_to_process.each do |item_data|
       product = item_data[:product]
       quantity = item_data[:requested]
       line_attrs = item_data[:line_attrs]
       unit_price_from_frontend = line_attrs[:unit_price]

       # Determine final price (prioritize frontend price)
       current_product_price = product.price rescue nil
       final_unit_price = unit_price_from_frontend.present? ? BigDecimal(unit_price_from_frontend) : current_product_price

       # Validate price again (should be non-nil and non-negative)
       if final_unit_price.nil? || final_unit_price < 0
           @invoice.errors.add(:base, "Invalid or missing price for product: #{product.name}.")
           Rails.logger.warn("Skipping invoice line due to invalid price for product ID #{product.id}: #{line_attrs.inspect}")
           next # Skip this line item
       end

       @invoice.invoice_lines.build(
          product_id: product.id,
          quantity: quantity,
          unit_price: final_unit_price
       )
    end

    # If errors were added during line building (e.g., price issue), stop before transaction
    unless @invoice.errors.empty?
        render json: { success: false, message: "Failed to build invoice lines.", errors: @invoice.errors.full_messages }, status: :unprocessable_entity
        return
    end

    # 5. Save Invoice, Update Stock & Create Payment in Transaction
    ActiveRecord::Base.transaction do
      # `update_totals` callback in Invoice model runs before save

      if @invoice.save # Saves invoice and lines due to association

        # Update stock levels atomically
        @invoice.invoice_lines.each do |line| # Iterate through saved lines
          # Use update_counters for atomic decrement
          # This should be safe as we validated stock earlier
          Product.update_counters(line.product_id, stock_quantity: -line.quantity)
        end

        # Create associated Payment record if payment method provided
        if payment_method_value.present?
           payment = Payment.new(
             invoice: @invoice,
             payment_method: payment_method_value,
             payment_status: payment_status_value,
             payment_date: Time.current,
             amount: @invoice.calculated_total_amount # Rely on model method
           )
           unless payment.save
               # Report payment failure and rollback transaction
               error_msg = "Invoice saved, but failed to record payment: #{payment.errors.full_messages.join(', ')}"
               @invoice.errors.add(:base, error_msg) # Add error to invoice object if needed
               Rails.logger.error(error_msg)
               raise ActiveRecord::Rollback # Rollback invoice save and stock update
           end
        end

        # If execution reaches here, transaction was successful
        render json: { success: true, invoice_id: @invoice.id, message: "Invoice created successfully." }, status: :created

      else
        # Invoice (or potentially line items) failed validation before saving
        # Transaction automatically rolls back
        render json: { success: false, message: "Failed to save invoice.", errors: @invoice.errors.full_messages }, status: :unprocessable_entity
      end
    end # End transaction

  # Rescue blocks handle errors outside/before the transaction or specific transaction failures like Rollback
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, message: "Invalid record referenced: #{e.message}" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e # Can be raised by payment.save! or potential future validations
     render json: { success: false, message: "Validation failed: #{e.message}", errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue ActiveRecord::Rollback => e # Catch explicit rollbacks (like from payment save failure)
      # The error should already be added to @invoice.errors or logged
      render json: { success: false, message: "Failed to complete transaction.", errors: @invoice.errors.full_messages.presence || ["Transaction rolled back."] }, status: :unprocessable_entity
  rescue => e # Catch other unexpected errors
    Rails.logger.error("Invoice creation failed unexpectedly: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { success: false, message: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
  end


  # GET /invoices/:id
  def show
    # Eager load associations needed for the show view
    @invoice = Invoice.includes(invoice_lines: { product: :category }, payments: {}, customer: {}).find(params[:id])
    render :show
  rescue ActiveRecord::RecordNotFound
    redirect_to invoices_path, alert: "Invoice not found." # Redirect to index
  end

  # GET /invoices/:id/printable
  def printable
    # Eager load associations needed for the printable view
    @invoice = Invoice.includes(invoice_lines: { product: :category }, payments: {}, customer: {}).find(params[:id])

    # --- RE-ADDED STATUS UPDATE LOGIC ---
    # Check current status and update if it's 'draft'
    # Use the enum directly for comparison and assignment for clarity and safety
    if @invoice.draft? # Check if current status is 'draft' using the enum helper
      @invoice.status = :paid # Set the new status to 'paid' using the enum symbol
      unless @invoice.save
        # Log error if save fails, but still render the printable view
        Rails.logger.error("Failed to update invoice #{@invoice.id} status to 'paid': #{@invoice.errors.full_messages.join(', ')}")
        # Optionally add a flash message if rendering HTML and layout supports flash
        # flash.now[:alert] = "Could not update invoice status."
      end
    end
    # --- END RE-ADDED STATUS UPDATE LOGIC ---

    # Render the printable view using the 'printable' layout
    render layout: 'printable', template: 'invoices/printable_show'

  rescue ActiveRecord::RecordNotFound
    # Handle case where invoice ID is invalid
    redirect_to invoices_path, alert: "Invoice not found." # Redirect to index
  end

  # --- PRIVATE METHODS START HERE ---
  private

  # Define parameters permitted for invoice creation/update
  def invoice_params
     params.require(:invoice).permit(
      # Invoice fields
      :customer_id,
      :invoice_date,
      :status, # Allow status like 'draft', 'issued'

      # Payment fields (extracted in action, not direct invoice attributes)
      :payment_method,
      :payment_status,

      # Nested attributes for lines
      invoice_lines_attributes: [
        :product_id,
        :quantity,
        :unit_price, # Permit unit_price from frontend
        :id,         # Needed for updates if you implement editing
        :_destroy    # Needed for removing lines if you implement editing
      ]
    )
  end

  # Placeholder for authentication check
  # def require_login
  #   unless current_user
  #     # Handle not logged in user, e.g., redirect or render error
  #   end
  # end

  # Make sure current_user helper is defined (likely in ApplicationController)
  # def current_user
  #   # ... logic to find logged-in user ...
  # end

  # Example: Ensure current_user is actually loaded before create/actions
  # def ensure_current_user_present
  #   unless current_user
  #     Rails.logger.error("Action requires current_user, but it is nil.")
  #     render json: { success: false, message: "User session not found. Please log in again." }, status: :unauthorized
  #   end
  # end

end