FactoryBot.define do
  factory :quote do
    account { nil }
    status { nil }
    approval_uri { "MyString" }
    quoted_account { nil }
    quoted_status { nil }
    state { 1 }
    legacy { false }
  end
end
