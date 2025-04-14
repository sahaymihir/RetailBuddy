# app/models/invoice_line.rb
class InvoiceLine < ApplicationRecord
  belongs_to :invoice
  belongs_to :product
end