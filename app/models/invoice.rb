# app/models/invoice.rb
class Invoice < ApplicationRecord
  belongs_to :customer
  has_many :invoice_lines, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :products, through: :invoice_lines

  accepts_nested_attributes_for :invoice_lines, allow_destroy: true

  # Define enum for status
  enum status: { draft: 0, issued: 1, paid: 2, cancelled: 3 }

  validates :customer_id, presence: true
  validates :invoice_date, presence: true
  # Removed validation for stored tax - it will be calculated
  # validates :tax, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :subtotal, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true # Keep if we store it

  # Callback to update totals before saving
  before_save :update_totals

  # Calculate total tax by summing tax from each line
  def calculated_total_tax
    invoice_lines.sum(&:line_tax).round(2) # Use the method from InvoiceLine
  end

  # Calculate total amount (subtotal + total tax)
  def calculated_total_amount
    (self.subtotal || 0) + calculated_total_tax # Use stored subtotal
  end

  # Calculate subtotal dynamically (alternative if not storing)
  # def calculated_subtotal
  #   invoice_lines.sum(&:line_subtotal).round(2)
  # end

  def self.ransackable_attributes(auth_object = nil)
    # Add status here if you want to search by it
    ["created_at", "customer_id", "due_date", "id", "id_value", "invoice_date", "status", "subtotal", "updated_at"] # Removed "tax"
  end

  def self.ransackable_associations(auth_object = nil)
    ["customer", "invoice_lines", "payments", "products"]
  end

  private

  # Update the subtotal before saving
  def update_totals
    # Calculate subtotal based on lines
    calculated_subtotal = invoice_lines.sum(&:line_subtotal).round(2)
    self.subtotal = calculated_subtotal
    # Note: We don't store total_tax or total_amount anymore, they are calculated dynamically
  end
end