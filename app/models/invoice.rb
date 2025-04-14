# app/models/invoice.rb
class Invoice < ApplicationRecord
  belongs_to :customer, optional: true # optional: true if customer can be nil
  belongs_to :user                 # The employee who created it
  has_many :invoice_lines, dependent: :destroy # If invoice deleted, delete lines
  has_many :products, through: :invoice_lines
  has_many :payments, dependent: :destroy   # If invoice deleted, delete payments
end