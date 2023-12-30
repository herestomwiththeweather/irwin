FactoryBot.define do
  factory :follow do
    account_id { 1 }
    target_account_id { 1 }
    identifier { "MyString" }
    uri { "MyString" }
  end
end
