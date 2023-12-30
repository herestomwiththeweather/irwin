FactoryBot.define do
  factory :status do
    language { "MyString" }
    uri { nil }
    visibility { 1 }
    text { "MyText" }

    before :create do |status|
      status.account ||= create :account
    end
  end
end
