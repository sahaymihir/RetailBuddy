# app/models/user.rb
class User < ApplicationRecord
  self.table_name = 'users'
  # --- ENSURE THIS LINE IS PRESENT ---
  self.sequence_name = "ISEQ$$_104835"
  # ------------------------------------
  self.primary_key = 'userid'

  # --- ADD THIS CALLBACK ---
  before_validation :clear_userid_for_new_record, on: :create
  # -------------------------

  # REMOVED: has_secure_password

  validates :userid, uniqueness: true, allow_nil: true # allow_nil is important here
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :role, presence: true, inclusion: { in: %w[Admin Employee] }
  validates :password, presence: true # Keep validation for plain text password

  # --- Keep existing methods ---
  def to_param
    userid.to_i.to_s # Consider if .to_i is appropriate for Oracle NUMBER, maybe just userid.to_s?
  end

  has_many :invoices, foreign_key: 'user_id', primary_key: 'userid', dependent: :destroy
  before_save { self.email = email.downcase }
  # --- End existing methods ---


  # --- ADD THIS PRIVATE METHOD ---
  private

  def clear_userid_for_new_record
    # If it's a new record (on: :create) and userid is somehow set (e.g. 0 or 0.0)
    # before validation runs, force it back to nil.
    # This ensures the :allow_nil validation passes for the initial check,
    # and lets the database use the specified sequence or identity column.
    if new_record? && !userid.nil? && userid.zero?
       self.userid = nil
    end
  end
  # ------------------------------

end