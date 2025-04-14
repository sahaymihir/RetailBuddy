# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_04_14_122306) do
  create_table "categories", force: :cascade do |t|
    t.string "category_name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "tax_percentage", precision: 5, scale: 2, default: "0.0"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "dbtools$execution_history", id: :decimal, force: :cascade do |t|
    t.text "hash"
    t.string "created_by"
    t.timestamptz "created_on", precision: 6
    t.string "updated_by"
    t.timestamptz "updated_on", precision: 6
    t.text "statement"
    t.decimal "times"
  end

  create_table "inventories", force: :cascade do |t|
    t.integer "product_id", precision: 38, null: false
    t.integer "reorder_level", precision: 38
    t.string "warehouse_location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_inventories_on_product_id"
  end

  create_table "invoice_lines", force: :cascade do |t|
    t.integer "invoice_id", precision: 38, null: false
    t.integer "product_id", precision: 38, null: false
    t.integer "quantity", precision: 38, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_lines_on_invoice_id"
    t.index ["product_id"], name: "index_invoice_lines_on_product_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "invoice_date", null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.integer "customer_id", precision: 38
    t.integer "user_id", precision: 38, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "subtotal", precision: 10, scale: 2
    t.integer "status", precision: 38, default: 0, null: false
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "payment_method", null: false
    t.string "payment_status", null: false
    t.datetime "payment_date", null: false
    t.integer "invoice_id", precision: 38, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "pricings", force: :cascade do |t|
    t.integer "product_id", precision: 38, null: false
    t.string "discount_rule"
    t.datetime "effective_date"
    t.datetime "expiry_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_pricings_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "product_name"
    t.decimal "price"
    t.integer "stock_quantity", precision: 38
    t.integer "category_id", precision: 38, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "users", primary_key: "userid", id: :decimal, default: "0.0", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "email", limit: 150, null: false
    t.string "password", null: false
    t.string "role", limit: 20, null: false
    t.string "password_digest"
    t.index ["email"], name: "sys_c0027878", unique: true
  end

  add_foreign_key "inventories", "products"
  add_foreign_key "invoice_lines", "invoices"
  add_foreign_key "invoice_lines", "products"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "users", primary_key: "userid"
  add_foreign_key "payments", "invoices"
  add_foreign_key "pricings", "products"
  add_foreign_key "products", "categories"
end
