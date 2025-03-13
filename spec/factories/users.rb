FactoryBot.define do
  factory :user do
    password { "abc123" }
    url { "https://example.com" }
  end
end
