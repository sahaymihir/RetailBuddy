# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  require 'csv'
  
  before_action :require_login
  # layout false # Keep or remove based on your needs

  def index
    # No specific data needed for the tile-based index page
  end

  # --- Action for Today's Sales Report (PAID invoices only) ---
  def todays_sales
    today_range = Time.zone.now.beginning_of_day..Time.zone.now.end_of_day

    # Fetch PAID invoices created today
    @todays_invoices = Invoice.where(invoice_date: today_range, status: :paid) # <-- Added status filter

    # Calculate total revenue from today's PAID invoices
    @total_revenue_today = @todays_invoices.sum(&:calculated_total_amount)

    # Count the number of PAID transactions (invoices)
    @transactions_today = @todays_invoices.count

    # Fetch payments linked to today's PAID invoices
    # Ensures payment summary only reflects paid transactions within the date range
    @payments_today = Payment.joins(:invoice) # Join with invoice to filter
                             .where(invoices: { id: @todays_invoices.pluck(:id) }) 

    @payment_summary = @payments_today.group(:payment_method).sum(:amount)

    @report_date = Time.zone.now.to_date

  rescue ArgumentError => e
     # ... (keep existing error handling) ...
     if e.message.include?('invalid date')
        flash.now[:alert] = "Invalid date format provided. Please use YYYY-MM-DD."
        @todays_invoices = Invoice.none # Ensure empty relation on error
        @total_revenue_today = 0
        @transactions_today = 0
        @payment_summary = {}
        @report_date = Time.zone.now.to_date
     else
        raise e
     end
  end

  # --- Action for Sales by Period Report (PAID invoices only) ---
  def sales_by_period
    # Parse dates safely, provide defaults
    begin
      @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
      @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month
    rescue ArgumentError
      flash[:alert] = "Invalid date format provided."
      @start_date = Date.current.beginning_of_month
      @end_date = Date.current.end_of_month
      # Consider redirecting back or rendering with defaults and error message
    end
  
    # Ensure end_date is inclusive for the query
    end_date_inclusive = @end_date.end_of_day
  
    # Fetch invoices within the date range
    @invoices = Invoice.includes(:customer) # Eager load customer
                       .where(invoice_date: @start_date.beginning_of_day..end_date_inclusive)
                       .order(invoice_date: :desc)
  
    # Calculate totals for HTML view (if needed)
    @total_sales = @invoices.sum(&:calculated_total_amount)
    @total_tax = @invoices.sum(&:calculated_total_tax)
  
    # --- Respond to different formats ---
    respond_to do |format|
      # HTML format (renders sales_by_period.html.erb implicitly)
      format.html
  
      # CSV format
      format.csv do
        # Define CSV headers
        headers = ["Invoice ID", "Date", "Customer Name", "Subtotal", "Tax", "Total Amount", "Status"]
  
        # Generate CSV data string
        csv_data = CSV.generate(headers: true) do |csv|
          csv << headers # Add header row
  
          # Add data rows for each invoice
          @invoices.each do |invoice|
            csv << [
              invoice.id,
              invoice.invoice_date.strftime('%Y-%m-%d'), # Format date
              invoice.customer&.name || 'N/A', # Handle nil customer
              invoice.subtotal,
              invoice.calculated_total_tax,
              invoice.calculated_total_amount,
              invoice.status.humanize
            ]
          end
  
          # Optionally add a summary row
          csv << [] # Blank row spacer
          csv << ["", "", "TOTALS:", @invoices.sum(&:subtotal), @total_tax, @total_sales, ""]
        end
  
        # Send the generated CSV data to the browser for download
        send_data csv_data,
                  filename: "sales-report-#{@start_date}-to-#{@end_date}.csv", # Dynamic filename
                  type: 'text/csv',
                  disposition: 'attachment' # Force download
      end
    end
  end

  # --- Action for Top Selling Products Report (based on PAID invoices only) ---
  def top_products
    # Set default date range
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Time.zone.now.beginning_of_month.to_date
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.now.to_date

    # Ensure end_date is not before start_date
    @end_date = @start_date if @end_date < @start_date

    date_range = @start_date.beginning_of_day..@end_date.end_of_day

    # Determine sorting criteria
    sort_by = params[:sort_by] == 'revenue' ? 'total_revenue' : 'total_quantity'
    @sort_by_param = params[:sort_by]

    # Fetch top products based on PAID invoices within the date range
    @top_products_data = InvoiceLine
      .joins(invoice: :products)
      .where(invoices: { invoice_date: date_range, status: :paid }) # <-- Added status filter here
      .group('products.id', 'products.product_name')
      .select(
        'products.id as product_id',
        'products.product_name',
        'SUM(invoice_lines.quantity) as total_quantity',
        'SUM(invoice_lines.quantity * invoice_lines.unit_price) as total_revenue'
      )
      .order("#{sort_by} DESC")
      .limit(10)

  rescue ArgumentError => e
    # ... (keep existing error handling) ...
    if e.message.include?('invalid date')
      flash.now[:alert] = "Invalid date format provided. Please use YYYY-MM-DD."
      @start_date = Time.zone.now.beginning_of_month.to_date
      @end_date = Time.zone.now.to_date
      @top_products_data = []
      @sort_by_param = 'quantity'
    else
      raise e
    end
  end

  def sales_by_category
    # Set default date range
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Time.zone.now.beginning_of_month.to_date
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.now.to_date

    # Ensure end_date is not before start_date
    @end_date = @start_date if @end_date < @start_date

    date_range = @start_date.beginning_of_day..@end_date.end_of_day

    # Fetch sales data grouped by category for PAID invoices within the date range
    @sales_by_category_data = Category
      .joins(products: { invoice_lines: :invoice }) # Join Category -> Product -> InvoiceLine -> Invoice
      .where(invoices: { invoice_date: date_range, status: :paid }) # Filter by date and paid status
      .group('categories.category_name') # Group by category name
      .select(
        'categories.category_name',
        'SUM(invoice_lines.quantity * invoice_lines.unit_price) as total_revenue' # Calculate sum of line subtotals
      )
      .order('total_revenue DESC') # Order by revenue descending

    # You might want total revenue for the period as well for context
    @total_revenue_period = @sales_by_category_data.sum(&:total_revenue)

  rescue ArgumentError => e
    if e.message.include?('invalid date')
      flash.now[:alert] = "Invalid date format provided. Please use YYYY-MM-DD."
      @start_date = Time.zone.now.beginning_of_month.to_date
      @end_date = Time.zone.now.to_date
      @sales_by_category_data = []
      @total_revenue_period = 0
    else
      raise e
    end
  end
  
  def top_customers
    # Set default date range
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Time.zone.now.beginning_of_month.to_date
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.now.to_date

    # Ensure end_date is not before start_date
    @end_date = @start_date if @end_date < @start_date

    date_range = @start_date.beginning_of_day..@end_date.end_of_day

    # Fetch top customers based on the sum of their PAID invoice line subtotals within the date range
    @top_customers_data = Customer
      .joins(invoices: :invoice_lines) # Join Customer -> Invoice -> InvoiceLine
      .where(invoices: { status: :paid, invoice_date: date_range }) # Filter by PAID status and date range
      .group('customers.id', 'customers.name') # Group by customer
      .select(
        'customers.id as customer_id',
        'customers.name as customer_name',
        'SUM(invoice_lines.quantity * invoice_lines.unit_price) as total_revenue' # Sum of line subtotals (pre-tax revenue)
      )
      .order('total_revenue DESC') # Order by highest revenue first
      .limit(20) # Show top 20 customers, adjust as needed

  rescue ArgumentError => e
    # Handle invalid date format errors
    if e.message.include?('invalid date')
      flash.now[:alert] = "Invalid date format provided. Please use YYYY-MM-DD."
      @start_date = Time.zone.now.beginning_of_month.to_date
      @end_date = Time.zone.now.to_date
      @top_customers_data = [] # Ensure empty array on error
    else
      raise e # Re-raise other argument errors
    end
  end

end