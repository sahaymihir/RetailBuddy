# db/migrate/20250414032721_add_subtotal_and_tax_to_invoices.rb
# You might consider renaming the file later to match the class name,
# e.g., 20250414032721_add_subtotal_to_invoices.rb, but fixing the content is key now.

class AddSubtotalAndTaxToInvoices < ActiveRecord::Migration[7.1] # <<< MAKE SURE CLASS NAME IS CHANGED HERE
  def change
    # Only add subtotal column with precision and scale
    add_column :invoices, :subtotal, :decimal, precision: 10, scale: 2

    # The line adding the tax column MUST be removed or commented out, like this:
    # add_column :invoices, :tax, :decimal, precision: 10, scale: 2
  end
end
