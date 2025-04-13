# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  before_action :require_login # Ensure user is logged in
  layout false # Render views in this controller without a layout

  def index
    # This page will mainly link to different report types or allow configuration.
    # No specific data loading needed for the index page itself yet.
  end

  # You would add actions here later to generate specific reports, e.g.:
  # def sales_report
  #   # Logic to generate sales data
  # end
  #
  # def tax_report
  #   # Logic to generate tax data
  # end
  #
  # def customer_report
  #   # Logic to generate customer data
  # end
end