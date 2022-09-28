class User < ApplicationRecord
  has_secure_password
  has_many :authorization_codes
  has_many :access_tokens
end
