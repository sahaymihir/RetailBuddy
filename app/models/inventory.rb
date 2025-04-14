# app/models/inventory.rb
class Inventory < ApplicationRecord
  # --- Add Aliases if needed (like in Product/Customer) ---
  # alias_attribute :reorder_level, :REORDER_LEVEL
  # alias_attribute :product_id, :PRODUCT_ID
  # ... other attributes

  # --- Associations ---
  belongs_to :product # Connects Inventory back to Product

  # --- Validations (example) ---
  validates :reorder_level, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :product_id, presence: true, uniqueness: true # Each product should have one inventory record
end