class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t| # Creates table 'customers' with default 'id' primary key
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.text :address
      t.timestamps null: false
    end
    # Add unique index if not added by generator 'uniq' flag
    add_index :customers, :email, unique: true
  end
end