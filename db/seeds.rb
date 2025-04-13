# db/seeds.rb

puts "Seeding Customers..."

# Optional: Clear existing customers first if you want to re-run seeds cleanly
# Customer.destroy_all

# Assumes 'customers' table exists with standard Rails 'id' primary key
# and attributes :name, :email, :phone, :address
Customer.create!([
  { name: 'Priya Sharma', email: 'priya.sharma@example.com', phone: '+919876543210', address: '12/A, MG Road, Koramangala, Bengaluru, 560034' },
  { name: 'Amit Patel', email: 'amit.patel@email.net', phone: '9123456789', address: 'Flat 5B, Green View Apartments, Jayanagar 4th Block, Bengaluru, 560011' },
  { name: 'Sneha Reddy', email: 's.reddy@domain.org', phone: '+917778889990', address: 'Plot No. 45, HSR Layout Sector 2, Bengaluru, 560102' },
  { name: 'Vikram Singh', email: 'vikram.s@mail.com', phone: nil, address: 'Shop No. 3, Commercial Street, Shivaji Nagar, Bengaluru, 560001' },
  { name: 'Anjali Rao', email: 'anjali.rao12@example.com', phone: '+918887776655', address: 'House No. 101, Indiranagar Stage 1, Bengaluru, 560038' }
])

puts "Finished seeding Customers (#{Customer.count} created)."

# You can add seeding for other models above or below this block if needed later.