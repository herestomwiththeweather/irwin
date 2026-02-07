FactoryBot.define do
  factory :network_event do
    host { nil }
    event_type { 1 }
    message { "MyText" }
    path { "MyString" }
    backtrace { "MyText" }
  end
end
