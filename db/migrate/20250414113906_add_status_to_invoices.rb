# db/migrate/YYYYMMDDHHMMSS_add_status_to_invoices.rb
class AddStatusToInvoices < ActiveRecord::Migration[7.1] # Adjust Rails version if needed
  def change
    # Add the status column as an integer
    # Set null: false if every invoice must have a status
    # Set default: 0 to default new invoices to the 'draft' status (since draft is 0 in your enum)
    add_column :invoices, :status, :integer, default: 0, null: false

    # Optional: Add an index for potentially faster status lookups
    add_index :invoices, :status
  end
end