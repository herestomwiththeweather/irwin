class Preference < ApplicationRecord
  belongs_to :user #representative

  validate :enforce_singleton, on: :create

  def enforce_singleton
    unless Preference.count == 0
      errors.add :base, "Attempting to instantiate another Preference object"
    end
  end
end
