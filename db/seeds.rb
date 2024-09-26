# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

preference = Preference.first
if preference.nil?
  USER_EMAIL = ENV['SMTP_DEFAULT_FROM'] || 'representative@example.com'
  USER_DOMAIN = ENV['SERVER_NAME'] || 'localhost'
  USER_NAME = 'representative'
  USER_URL = "https://#{USER_DOMAIN}/representative"
  password =  SecureRandom.hex

  u=User.new(email: USER_EMAIL, password: password, password_confirmation: password, domain: USER_DOMAIN, username: USER_NAME, url: USER_URL)
  actor_url = u.actor_url
  u.account = Account.create!(  preferred_username: u.username,
                                              name: u.username,
                                               url: u.url,
                                            domain: u.domain,
                                        identifier: actor_url,
                                             inbox: "#{actor_url}/inbox",
                                            outbox: "#{actor_url}/outbox",
                                         followers: "#{actor_url}/followers",
                                         following: "#{actor_url}/following" )
  u.generate_keys
  u.save(validate: false)
  Preference.create!(user: u)
end
