class IpBlock < ApplicationRecord
  CACHE_KEY = 'blocked_ips'

  validates :ip, presence: true
  after_commit :reset_cache

  def self.blocked?(remote_ip)
    cached_ips.include?(remote_ip)
  end

  def self.cached_ips
    Rails.cache.fetch(CACHE_KEY) { pluck(:ip).map(&:to_s).to_set }
  end

  private

  def reset_cache
    Rails.cache.delete(CACHE_KEY)
  end
end
