class BillingController < ApplicationController
  before_action :require_login # Make sure this filter exists in ApplicationController
  layout false, only: [:new]
  def new
    # Add any setup logic needed for the page here.
    # For example, initialize a new bill object:
    # @bill = Bill.new
    # @bill_items = []
  end

  # You might add a 'create' action later to handle form submission
  # def create
  #   # ... process the finalized bill ...
  # end
end