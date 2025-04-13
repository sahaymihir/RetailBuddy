# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :category
  has_many :invoice_lines
  has_one :inventory, dependent: :destroy # Assuming one-to-one inventory mapping
  alias_attribute :name, :product_name
  accepts_nested_attributes_for :inventory # Keep this

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category_id, presence: true

  # Delegate tax percentage to category for easier access
  delegate :tax_percentage, to: :category, prefix: false, allow_nil: true # Use allow_nil: true if category might be optional

  # Ensure inventory exists after create <<< REMOVE THE CALLBACK REFERENCE
  # after_create :create_default_inventory   # <<< REMOVED THIS LINE

  def self.ransackable_attributes(auth_object = nil)
    ["category_id", "created_at", "description", "id", "id_value", "name", "price", "updated_at", "stock_quantity"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["category", "invoice_lines", "inventory"]
  end

  # Method to get tax rate (handles potential nil category/percentage)
  def applicable_tax_rate
    tax_percentage || 0.0 # Relies on delegate defined above
  end

  # private <<< REMOVE THIS METHOD BLOCK
    # def create_default_inventory
    #   Inventory.create(product: self, quantity: 0) unless inventory.present?
    # end
end