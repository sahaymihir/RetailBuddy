class AddTaxPercentageToCategories < ActiveRecord::Migration[7.1] # Adjust version if needed
  def change
    add_column :categories, :tax_percentage, :decimal, precision: 5, scale: 2, default: 0.0
  end
end