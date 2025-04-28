# Clean DB
Customer.destroy_all
User.destroy_all
Category.destroy_all
Product.destroy_all
Inventory.destroy_all

# Users
User.create!(name: 'Admin User', email: 'admin@retailbuddy.com', role: 'Admin', password: 'password123')
User.create!(name: 'Staff User', email: 'staff@retailbuddy.com', role: 'Employee', password: 'password123')

# Categories
cat_el = Category.create!(name: 'Electronics', description: 'Gadgets and devices', tax_percentage: 18.0)
cat_ac = Category.create!(name: 'Accessories', description: 'Tech accessories', tax_percentage: 12.0)
cat_fu = Category.create!(name: 'Furniture', description: 'Office furniture', tax_percentage: 5.0)

# Products & Inventory
p1 = Product.create!(name: 'Wireless Keyboard', price: 1299.0, stock_quantity: 45, category: cat_el)
Inventory.create!(product: p1, reorder_level: 10, warehouse_location: 'A1')

p2 = Product.create!(name: 'USB-C Hub', price: 2499.0, stock_quantity: 30, category: cat_ac)
Inventory.create!(product: p2, reorder_level: 5, warehouse_location: 'B2')

p3 = Product.create!(name: 'Monitor Stand', price: 899.0, stock_quantity: 8, category: cat_fu)
Inventory.create!(product: p3, reorder_level: 10, warehouse_location: 'C3')

p4 = Product.create!(name: 'Mechanical Keyboard', price: 3499.0, stock_quantity: 22, category: cat_el)
Inventory.create!(product: p4, reorder_level: 8, warehouse_location: 'A2')

p5 = Product.create!(name: 'Laptop Bag', price: 1199.0, stock_quantity: 15, category: cat_ac)
Inventory.create!(product: p5, reorder_level: 5, warehouse_location: 'B1')

p6 = Product.create!(name: 'Desk Lamp', price: 599.0, stock_quantity: 3, category: cat_fu)
Inventory.create!(product: p6, reorder_level: 10, warehouse_location: 'C1')

# Customers
Customer.create!(name: 'Priya Sharma', email: 'priya.sharma@example.com', phone: '+919876543210', address: '12/A, MG Road, Koramangala, Bengaluru, 560034')
Customer.create!(name: 'Amit Patel', email: 'amit.patel@email.net', phone: '9123456789', address: 'Flat 5B, Green View Apartments, Jayanagar 4th Block, Bengaluru, 560011')
Customer.create!(name: 'Sneha Reddy', email: 's.reddy@domain.org', phone: '+917778889990', address: 'Plot No. 45, HSR Layout Sector 2, Bengaluru, 560102')

# Invoices (Past Sales Data)
admin = User.first
c1 = Customer.first

i1 = Invoice.create!(customer: c1, user_id: admin.userid, invoice_date: Date.today, status: :paid)
l1 = InvoiceLine.create!(invoice: i1, product: p1, quantity: 2, unit_price: p1.price)
l2 = InvoiceLine.create!(invoice: i1, product: p2, quantity: 1, unit_price: p2.price)
i1.save!
Payment.create!(invoice: i1, payment_method: 'Card', payment_status: 'Completed', payment_date: Date.today, amount: i1.calculated_total_amount)

i2 = Invoice.create!(customer: Customer.last, user_id: admin.userid, invoice_date: Date.today, status: :paid)
l3 = InvoiceLine.create!(invoice: i2, product: p4, quantity: 1, unit_price: p4.price)
i2.save!
Payment.create!(invoice: i2, payment_method: 'UPI', payment_status: 'Completed', payment_date: Date.today, amount: i2.calculated_total_amount)
