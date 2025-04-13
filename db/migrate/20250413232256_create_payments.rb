# db/migrate/YYYYMMDDHHMMSS_create_payments.rb
class CreatePayments < ActiveRecord::Migration[7.1] # Or your Rails version
  def change
    create_table :payments do |t|
      t.string :payment_method, null: false # e.g., 'Cash', 'Card', 'UPI'
      t.string :payment_status, null: false # e.g., 'Completed', 'Pending', 'Failed'
      t.datetime :payment_date, null: false # When the payment was made/attempted
      t.references :invoice, null: false, foreign_key: true # Payment is for which invoice

      t.timestamps null: false
    end
  end
end