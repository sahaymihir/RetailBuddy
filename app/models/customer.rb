# app/models/customer.rb
class Customer < ApplicationRecord
  # Ensure table_name/primary_key are set correctly ONLY if not using Rails defaults
  # self.table_name = 'ADMIN.customers' # Or 'customers'
  # self.primary_key = 'id' # Or 'CustomerID' if using the VARCHAR2 setup

  # --- Validations ---
  validates :name, presence: true
  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { email.present? }

  # --- Associations ---
  has_many :invoices
end
