class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  validates :email_address, presence: true, uniqueness: true
  validates :password, confirmation: true
  validates :password_confirmation, presence: true
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :job_applications, dependent: :destroy
end
