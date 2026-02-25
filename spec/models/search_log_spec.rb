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

    include_examples "validates presence of attribute",
                     :search_log,
                     :query,
                     :blank_query

    include_examples "validates presence of attribute",
                     :search_log,
                     :converted_text,
                     :blank_converted_text

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

    include_examples "validates max length of attribute",
                     :search_log,
                     :converted_text,
                     :too_long
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
