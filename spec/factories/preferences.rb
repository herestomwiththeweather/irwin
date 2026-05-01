FactoryBot.define do
  factory :preference do
    user
    enable_registrations { false }
  end
end
