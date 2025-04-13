class PagesController < ApplicationController
  layout false
  before_action :require_login, only: [:success]
  def index
    # Home page logic (if any)
  end

  def success
    # Logic for success page (if any)
  end
end