class AddAmountToPayments < ActiveRecord::Migration[7.1] # Or your Rails version
  def change
    add_column :payments, :amount, :decimal, precision: 10, scale: 2
    # You might want to add null: false if a payment always must have an amount
    # add_column :payments, :amount, :decimal, precision: 10, scale: 2, null: false
  end
end