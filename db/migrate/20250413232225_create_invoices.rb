# db/migrate/20250413232225_create_invoices.rb
class CreateInvoices < ActiveRecord::Migration[7.1] # Or your Rails version
  def change
    create_table :invoices do |t|
      t.datetime :invoice_date, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.decimal :discount, precision: 10, scale: 2, default: 0.0
      # Assuming customers table uses standard 'id' primary key from migration:
      t.references :customer, null: true, foreign_key: true

      # Tell references about the non-standard primary key on the users table:
      # Also specify the correct type (likely integer/bigint for the foreign key,
      # even if the primary key is decimal, unless you need decimal FKs)
      t.references :user, null: false, foreign_key: { primary_key: :userid }, type: :integer # Or :bigint

      t.timestamps null: false
    end
  end
end