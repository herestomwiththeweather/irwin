require 'rails_helper'

RSpec.describe Account, type: :model do
  describe "when creating a new account" do
    before do
      @account = FactoryBot.create(:account)
    end

    it "should be valid" do
      expect(@account).to be_valid
    end
  end
end
