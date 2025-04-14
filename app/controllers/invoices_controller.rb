# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  # Assuming require_login and other before_actions are correctly defined elsewhere
  # For example: before_action :require_login
  # Ensure current_user is available if needed for user_id assignment

  # POST /invoices
  
  def index
    # Paginate for performance if you have many invoices
    @invoices = Invoice.order(invoice_date: :desc).paginate(page: params[:page], per_page: 20) # Example pagination
    # Or simply: @invoices = Invoice.order(invoice_date: :desc).all
  end
  
  def create
    # 1. Separate invoice header params from line items and payment details
    invoice_data = invoice_params # Use strong params

    # Extract nested attributes and payment info *before* initializing Invoice
    invoice_lines_data = invoice_data.delete(:invoice_lines_attributes) || []
    payment_method_value = invoice_data.delete(:payment_method)
    # Default payment status to 'Completed' if not provided
    payment_status_value = invoice_data.delete(:payment_status) || 'Completed'

    # Ensure we have line items
    if invoice_lines_data.empty?
      render json: { success: false, message: "Cannot create an invoice with no items." }, status: :unprocessable_entity
      return
    end

    # 2. Initialize Invoice ONLY with attributes belonging to the Invoice model
    @invoice = Invoice.new(invoice_data) # invoice_data now only contains Invoice fields
    @invoice.invoice_date ||= Time.current
    @invoice.status ||= 'draft' # Default status to draft if not provided

    # Assign current user
    if current_user
      @invoice.user_id = current_user.userid # Assign the foreign key directly
    else
      Rails.logger.error("Cannot create invoice: current_user is nil.")
      render json: { success: false, message: "User session not found. Please log in again." }, status: :unauthorized
      return
    end

    # 3. Manually build invoice lines, prioritizing frontend price
    invoice_lines_data.each do |line_attrs|
      product = Product.find_by(id: line_attrs[:product_id])
      quantity = line_attrs[:quantity].to_i
      unit_price_from_frontend = line_attrs[:unit_price] # Already permitted

      if product && quantity > 0
        current_product_price = product.price rescue nil
        final_unit_price = unit_price_from_frontend || current_product_price

        if final_unit_price.nil? || final_unit_price.to_f < 0 # Ensure it's treated as number
           @invoice.errors.add(:base, "Invalid or missing price for product ID #{product.id}.")
           Rails.logger.warn("Skipping invoice line due to invalid price: #{line_attrs.inspect}")
           next
        end

        @invoice.invoice_lines.build(
          product_id: product.id,
          quantity: quantity,
          unit_price: final_unit_price
        )
      else
        error_message = if !product
                          "Invalid product ID #{line_attrs[:product_id] || 'N/A'}."
                        else
                          "Invalid quantity for product ID #{product.id}."
                        end
        @invoice.errors.add(:base, error_message)
        Rails.logger.warn("Skipping invalid invoice line item: #{line_attrs.inspect}")
      end
    end

    # If errors were added during line building, stop before transaction
    unless @invoice.errors.empty?
        render json: { success: false, message: "Failed to build invoice lines.", errors: @invoice.errors.full_messages }, status: :unprocessable_entity
        return
    end


    # 4. Save Invoice & Create Payment in Transaction
    ActiveRecord::Base.transaction do
      # Calculate totals using model callbacks before saving
      if @invoice.save

        # Update stock levels atomically
        @invoice.invoice_lines.reload.each do |line|
          Product.update_counters(line.product_id, stock_quantity: -line.quantity)
          # Optional: Check for negative stock here and raise ActiveRecord::Rollback if needed
        end

        # Create associated Payment record only if payment details provided
        if payment_method_value.present?
           payment = Payment.new(
             invoice: @invoice,
             payment_method: payment_method_value,
             payment_status: payment_status_value,
             payment_date: Time.current,
             amount: @invoice.calculated_total_amount # Assumes amount column exists now
           )
           unless payment.save
               # Use invoice errors to report payment failure within the transaction response
               @invoice.errors.add(:base, "Invoice saved, but failed to record payment: #{payment.errors.full_messages.join(', ')}")
               raise ActiveRecord::Rollback # Rollback invoice save and stock update
           end
        end

        # Success response after all transaction steps succeed
        render json: { success: true, invoice_id: @invoice.id, message: "Invoice created successfully." }, status: :created
      else
        # Invoice save failure response (will trigger rollback automatically)
        render json: { success: false, message: "Failed to save invoice.", errors: @invoice.errors.full_messages }, status: :unprocessable_entity
      end
    end # End transaction

  # Rescue blocks moved outside the transaction block if they handle errors before the transaction starts
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, message: "Invalid product referenced: #{e.message}" }, status: :not_found
  # RecordInvalid might be raised from within the transaction, keep it outside or handle rollback explicitly
  rescue ActiveRecord::RecordInvalid => e
     render json: { success: false, message: "Failed to save related record: #{e.message}", errors: e.record.errors.full_messages }, status: :unprocessable_entity
  # General error rescue
  rescue => e
    Rails.logger.error("Invoice creation failed unexpectedly: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { success: false, message: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
  end


  # GET /invoices/:id
  def show
    @invoice = Invoice.includes(invoice_lines: :product, payments: {}).find(params[:id])
    # Render your show view (assuming standard Rails convention, e.g., app/views/invoices/show.html.erb)
    render :show
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invoice not found."
  end

  # GET /invoices/:id/printable
  def printable
    @invoice = Invoice.includes(invoice_lines: :product, payments: {}, customer: {}).find(params[:id]) # Eager load associations

    # Check current status and update if it's 'draft'
    if @invoice.status&.downcase == 'draft'
      @invoice.status = 'paid' # Set the new status
      unless @invoice.save
        # Log error if save fails, but still render
        Rails.logger.error("Failed to update invoice #{@invoice.id} status to 'paid': #{@invoice.errors.full_messages.join(', ')}")
        # Optionally add a flash message for the UI if rendering HTML and layout supports flash
        # flash.now[:alert] = "Could not update invoice status."
      end
    end

    # --- RENDER CALL RE-ADDED ---
    # Render the printable view using the 'printable' layout
    render layout: 'printable', template: 'invoices/printable_show'

  # --- ADDED RESCUE BLOCK ---
  rescue ActiveRecord::RecordNotFound
    # Handle case where invoice ID is invalid
    redirect_to root_path, alert: "Invoice not found."
  end

  # --- PRIVATE METHODS START HERE ---
  private

  # Define parameters permitted for the main Invoice model AND nested lines
  def invoice_params
     params.require(:invoice).permit(
      # Invoice fields
      :customer_id,
      :invoice_date,
      :status, # Allow status like 'draft' to be set initially

      # Payment fields (extracted in action)
      :payment_method,
      :payment_status,

      # Nested attributes for lines
      invoice_lines_attributes: [
        :product_id,
        :quantity,
        :unit_price, # Permit unit_price from frontend
        :id,
        :_destroy
      ]
    )
  end

  # Example require_login method (adapt to your auth system)
  # def require_login
  #   # ... your authentication logic ...
  # end

  # Make sure current_user helper is defined, perhaps in ApplicationController
  # def current_user
  #   # ... logic to find logged-in user ...
  # end

end