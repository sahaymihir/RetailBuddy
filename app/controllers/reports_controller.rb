# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
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
                             .where(invoices: { id: @todays_invoices.pluck(:id) }) # Filter by the IDs of today's paid invoices
                             # Alternative: Filter payment date as well if needed: .where(payment_date: today_range)

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
    # Set default date range
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Time.zone.now.beginning_of_month.to_date
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Time.zone.now.to_date

    # Ensure end_date is not before start_date
    @end_date = @start_date if @end_date < @start_date

    date_range = @start_date.beginning_of_day..@end_date.end_of_day

    # Fetch PAID invoices within the date range - ADDED includes(:customer) and assigned to instance variable
    @invoices_in_period = Invoice.includes(:customer).where(invoice_date: date_range, status: :paid).order(invoice_date: :desc) # Added order

    # Group PAID invoices by day (Uses the same collection)
    sales_grouped_by_day = @invoices_in_period.group_by { |inv| inv.invoice_date.to_date }

    # Process the grouped data for the view
    @sales_by_day_data = sales_grouped_by_day.map do |date, invoices|
      {
        date: date,
        revenue: invoices.sum(&:calculated_total_amount),
        transactions: invoices.count
      }
    end.sort_by { |data| data[:date] } # Keep sort by date for the daily summary

    # Calculate overall totals for the period from PAID invoices
    @total_revenue_period = @sales_by_day_data.sum { |data| data[:revenue] }
    @total_transactions_period = @invoices_in_period.count # Count the fetched invoices

  rescue ArgumentError => e
     if e.message.include?('invalid date')
      flash.now[:alert] = "Invalid date format provided. Please use YYYY-MM-DD."
      @start_date = Time.zone.now.beginning_of_month.to_date
      @end_date = Time.zone.now.to_date
      @sales_by_day_data = []
      @invoices_in_period = Invoice.none # Ensure empty relation on error
      @total_revenue_period = 0
      @total_transactions_period = 0
    else
      raise e
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