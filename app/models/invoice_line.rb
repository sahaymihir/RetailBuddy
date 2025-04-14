# app/models/invoice_line.rb
class InvoiceLine < ApplicationRecord
  belongs_to :invoice
  belongs_to :product

  def total_price
    quantity * unit_price
  end
end