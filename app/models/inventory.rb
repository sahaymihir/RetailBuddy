# app/models/inventory.rb
class Inventory < ApplicationRecord
  # --- Add Aliases if needed (like in Product/Customer) ---
  # alias_attribute :reorder_level, :REORDER_LEVEL
  # alias_attribute :product_id, :PRODUCT_ID
  # ... other attributes

  # --- Associations ---
  belongs_to :product # Connects Inventory back to Product

  # --- Validations ---
  validates :reorder_level, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Validate the presence of the associated product object, not the foreign key id
  validates :product, presence: true

  # Removed: validates :product_id, presence: true, uniqueness: true
  # The `uniqueness: true` validation here is also generally discouraged.
  # It's better enforced by a database unique index on inventories.product_id
  # and the `has_one :inventory` association in the Product model.
end