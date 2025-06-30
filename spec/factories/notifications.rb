FactoryBot.define do
  factory :notification do
    user { nil }
    account { nil }
    status { nil }
    read_at { "2025-06-29 17:56:42" }
    message { "MyString" }
    type { "" }
  end
end
