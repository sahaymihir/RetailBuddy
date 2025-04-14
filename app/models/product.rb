# app/models/product.rb
class Product < ApplicationRecord
  # --- Associations ---
  belongs_to :category
  has_one :inventory, dependent: :destroy
  has_many :invoice_lines, dependent: :destroy # Added dependent: :destroy
  has_many :invoices, through: :invoice_lines
  accepts_nested_attributes_for :inventory, allow_destroy: true

  # --- Validations ---
  validates :product_name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :category_id, presence: true

end