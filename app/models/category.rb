class Category < ApplicationRecord
  self.sequence_name = 'categories_seq'
  # Explicitly set table name if it doesn't follow convention (categories)
  # self.table_name = 'your_category_table_name' # Uncomment and set if needed

  # Define associations
  has_many :products
  # Add any validations needed
  # validates :category_name, presence: true
  # ... other model logic ...
end
