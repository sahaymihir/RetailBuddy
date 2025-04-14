# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :invoice
end