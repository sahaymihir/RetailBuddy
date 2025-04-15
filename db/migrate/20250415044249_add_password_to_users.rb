# db/migrate/YYYYMMDDHHMMSS_add_password_to_users.rb
class AddPasswordToUsers < ActiveRecord::Migration[7.1] # Adjust version if needed
  def change
    add_column :users, :password, :string
  end
end