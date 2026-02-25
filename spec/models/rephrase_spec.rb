require "rails_helper"

RSpec.describe Rephrase, type: :model do
  describe "associations" do
    it "belongs to category" do
      association = described_class.reflect_on_association(:category)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    subject(:rephrase) { build(:rephrase) }

    it "is valid with factory defaults" do
      expect(rephrase).to be_valid
    end

    include_examples "validates presence of attribute",
                     :rephrase,
                     :content,
                     :invalid

    include_examples "validates max length of attribute",
                     :rephrase,
                     :content,
                     :too_long
  end
end
