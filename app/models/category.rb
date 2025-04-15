# app/models/category.rb
class Category < ApplicationRecord
  alias_attribute :name, :category_name
  alias_attribute :description, :description # Handles the DESCRIPTION column
  has_many :products, dependent: :restrict_with_error # Ensure categories aren't deleted if products exist

  validates :name, presence: true, uniqueness: true
  validates :tax_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "name", "updated_at", "tax_percentage"]
  end
end