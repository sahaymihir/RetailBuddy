# db/migrate/YYYYMMDDHHMMSS_remove_total_amount_from_invoices.rb
class RemoveTotalAmountFromInvoices < ActiveRecord::Migration[7.1] # Adjust version if needed
  def change
    # Remove the total_amount column from the invoices table
    remove_column :invoices, :total_amount, :decimal, precision: 10, scale: 2
  end
end