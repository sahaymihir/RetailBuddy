class User < ApplicationRecord
  self.table_name = 'users' # Explicitly use Oracle's users table

  validates :userid, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true
  validates :role, presence: true, inclusion: { in: %w[Admin Employee] }

  def authenticate(input_password)
    self.password == input_password # Plain-text password validation (consider encryption later)
  end

  def to_param
    userid.to_i.to_s # Convert the decimal userid to integer, then back to string
  end

  has_many :invoices
end
