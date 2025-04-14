# db/migrate/YYYYMMDDHHMMSS_create_invoice_lines.rb
class CreateInvoiceLines < ActiveRecord::Migration[7.1] # Or your Rails version
  def change
    create_table :invoice_lines do |t|
      t.references :invoice, null: false, foreign_key: true # Belongs to an invoice
      t.references :product, null: false, foreign_key: true # References a product
      t.integer :quantity, null: false                 # How many were bought
      t.decimal :unit_price, precision: 10, scale: 2, null: false # Price per unit AT TIME OF SALE

      t.timestamps null: false
    end
  end
end