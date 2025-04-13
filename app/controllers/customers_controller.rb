# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  before_action :require_login
  layout false # Render views without a layout

  # GET /customers
  def index
    # Fetch customers - add search/pagination later
    # @customers = Customer.all
    @customers = [] # Placeholder for now
  end

  # GET /customers/1
  def show
    # @customer = Customer.find(params[:id])
    # Placeholder
  end

  # GET /customers/new
  def new
    # @customer = Customer.new
    # Placeholder
  end

  # GET /customers/1/edit
  def edit
    # @customer = Customer.find(params[:id])
    # Placeholder
  end

  # POST /customers
  def create
    # @customer = Customer.new(customer_params)
    # if @customer.save
    #   redirect_to customers_path, notice: 'Customer was successfully created.'
    # else
    #   render :new, status: :unprocessable_entity
    # end
    # Placeholder redirect
    redirect_to customers_path, notice: "Customer creation logic needed."
  end

  # PATCH/PUT /customers/1
  def update
     # @customer = Customer.find(params[:id])
     # if @customer.update(customer_params)
     #   redirect_to customers_path, notice: 'Customer was successfully updated.'
     # else
     #   render :edit, status: :unprocessable_entity
     # end
     # Placeholder redirect
     redirect_to customers_path, notice: "Customer update logic needed."
  end

  # DELETE /customers/1
  def destroy
    # @customer = Customer.find(params[:id])
    # @customer.destroy
    # redirect_to customers_url, notice: 'Customer was successfully destroyed.'
    # Placeholder redirect
    redirect_to customers_path, notice: "Customer deletion logic needed."
  end

  private
  # Only allow a list of trusted parameters through.
  # def customer_params
  #   params.require(:customer).permit(:Name, :Email, :Phone, :Address) # Use exact column names from ERD
  # end
end
