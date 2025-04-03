# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  before_action :require_login
  before_action :set_customer, only: [:show, :edit, :update, :destroy] # Add actions that need @customer
  # If rendering full HTML pages:
  # layout false

  def index
    @customers = Customer.all
    # --- Add Search Logic ---
    if params[:search_query].present?
      query_term = "%#{params[:search_query]}%"
      @customers = @customers.where(
        "name LIKE :search OR email LIKE :search OR phone LIKE :search",
        search: query_term
      )
    end
    # --- End Search Logic ---
    @customers = @customers.order(:name) # Order results
  end

  # GET /customers/new
  def new
    @customer = Customer.new
  end

  # POST /customers
  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      redirect_to customers_path, notice: 'Customer was successfully created.'
    else
      flash.now[:alert] = "Failed to create customer."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /customers/:id/edit - Action for the Edit button link
  def edit
    # @customer is set by before_action
  end

  # PATCH/PUT /customers/:id - Action for submitting the Edit form
  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: 'Customer was successfully updated.'
    else
      flash.now[:alert] = "Failed to update customer."
      render :edit, status: :unprocessable_entity # Re-render edit form with errors
    end
  end

  # DELETE /customers/:id - Action for the Delete button
  def destroy
    begin
      @customer.destroy!
      redirect_to customers_path, notice: 'Customer was successfully deleted.', status: :see_other
    rescue => e
      redirect_to customers_path, alert: "Failed to delete customer: #{e.message}"
    end
  end

  # GET /customers/:id (Optional Show action)
  def show
    # @customer is set by before_action
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  rescue ActiveRecord::RecordNotFound
     redirect_to customers_path, alert: "Customer not found."
  end

  # Define permitted parameters using lowercase symbols matching model attributes
  def customer_params
    params.require(:customer).permit(:name, :email, :phone, :address)
  end

end