# app/models/invoice_line.rb
class InvoiceLine < ApplicationRecord
  belongs_to :invoice
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Calculate subtotal for this line item (before tax)
  def line_subtotal
    quantity * unit_price
  end

  # Calculate tax for this line item
  def line_tax
    # Ensure product and its tax rate are available
    rate = product&.applicable_tax_rate || 0.0
    line_subtotal * (rate / 100.0)
  end

  # Calculate total for this line item (including tax)
  def line_total
    line_subtotal + line_tax
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "invoice_id", "product_id", "quantity", "unit_price", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["invoice", "product"]
  end
end