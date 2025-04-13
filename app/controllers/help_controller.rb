# app/controllers/help_controller.rb
class HelpController < ApplicationController
  before_action :require_login # Ensure user is logged in
  layout false # Render views in this controller without a layout

  def index
    # This is mostly a static page, maybe load FAQs from DB later
  end
end