class Preference < ApplicationRecord
  validate :enforce_singleton, on: :create

  def enforce_singleton
    unless Preference.count == 0
      errors.add :base, "Attempting to instantiate another Preference object"
    end
  end
end
