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

    context "when content is blank" do
      subject(:rephrase) { build(:rephrase, :invalid) }

      it "is invalid" do
        expect(rephrase).to be_invalid
      end

      it "adds a blank error" do
        rephrase.validate
        expect(rephrase.errors[:content]).to include("can't be blank")
      end
    end

    context "when content exceeds 300 characters" do
      subject(:rephrase) { build(:rephrase, :too_long) }

      it "is invalid" do
        expect(rephrase).to be_invalid
      end

      it "adds a too long error" do
        rephrase.validate
        expect(rephrase.errors[:content]).to include("is too long (maximum is 300 characters)")
      end
    end
  end
end
