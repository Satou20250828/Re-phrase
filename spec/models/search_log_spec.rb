require "rails_helper"

RSpec.describe SearchLog, type: :model do
  describe "associations" do
    it "belongs to category" do
      association = described_class.reflect_on_association(:category)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "enums" do
    it "defines hit_type enum" do
      expect(described_class.hit_types).to eq(
        "exact" => 0,
        "partial" => 1,
        "none" => 2
      )
    end
  end

  describe "validations" do
    subject(:search_log) { build(:search_log) }

    it "is valid with factory defaults" do
      expect(search_log).to be_valid
    end

    context "when query is blank" do
      subject(:search_log) { build(:search_log, query: nil) }

      it "is invalid" do
        expect(search_log).to be_invalid
      end

      it "adds a blank error" do
        search_log.validate
        expect(search_log.errors[:query]).to include("can't be blank")
      end
    end

    context "when converted_text is blank" do
      subject(:search_log) { build(:search_log, converted_text: nil) }

      it "is invalid" do
        expect(search_log).to be_invalid
      end

      it "adds a blank error" do
        search_log.validate
        expect(search_log.errors[:converted_text]).to include("can't be blank")
      end
    end

    context "when hit_type is nil" do
      subject(:search_log) { build(:search_log, hit_type: nil) }

      it "normalizes to none and stays valid" do
        search_log.validate
        expect(search_log.hit_type).to eq("none")
        expect(search_log).to be_valid
      end
    end

    context "when hit_type is blank" do
      subject(:search_log) { build(:search_log, :blank_hit_type) }

      it "normalizes to none and stays valid" do
        search_log.validate
        expect(search_log.hit_type).to eq("none")
        expect(search_log).to be_valid
      end
    end

    context "when converted_text exceeds 300 characters" do
      subject(:search_log) { build(:search_log, :too_long) }

      it "is invalid" do
        expect(search_log).to be_invalid
      end

      it "adds a too long error" do
        search_log.validate
        expect(search_log.errors[:converted_text]).to include("is too long (maximum is 300 characters)")
      end
    end
  end

  describe "callbacks" do
    context "when category is missing" do
      subject(:search_log) { build(:search_log, :without_category) }

      it "auto-completes category with default name" do
        search_log.validate
        expect(search_log.category).to be_present
        expect(search_log.category.name).to eq(SearchLog::DEFAULT_CATEGORY_NAME)
      end
    end
  end
end
