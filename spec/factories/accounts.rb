FactoryBot.define do
  factory :account do
    sequence(:identifier) {|i| "https://example.com/abc#{i}" }
    sequence(:following) {|i| "https://example.com/abc#{i}" }
    sequence(:followers) {|i| "https://example.com/abc#{i}" }
    sequence(:inbox) {|i| "https://example.com/abc#{i}" }
    sequence(:outbox) {|i| "https://example.com/abc#{i}" }
    sequence(:url) { |i| "https://example.com/abc#{i}" }
    sequence(:name) { |i| "abc#{i}" }
  end
end
