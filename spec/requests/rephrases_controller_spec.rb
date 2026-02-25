require "rails_helper"

RSpec.describe "RephrasesController", type: :request do
  describe "GET /search" do
    subject(:perform_request) { get search_path, params: params }

    let(:category) { create(:category) }
    let(:query) { "ごめん" }
    let(:params) { { q: query, category_id: category.id } }

    context "when SearchLog is saved" do
      before do
        create(:rephrase, category: category, content: "ごめん→「失礼いたしました」")
        perform_request
      end

      it "returns OK" do
        expect(response).to have_http_status(:ok)
      end

      it "shows converted text" do
        expect(response.body).to include("失礼いたしました")
      end

      it "stores the query" do
        expect(SearchLog.last&.query).to eq(query)
      end

      it "stores converted text" do
        expect(SearchLog.last&.converted_text).to eq("失礼いたしました")
      end

      it "stores category id" do
        expect(SearchLog.last&.category_id).to eq(category.id)
      end

      it "stores hit type" do
        expect(SearchLog.last&.hit_type).to eq("partial")
      end

      it "stores safety mode flag" do
        expect(SearchLog.last&.safety_mode_applied).to be(false)
      end
    end

    context "when SearchLog save fails" do
      before do
        create(:rephrase, category: category, content: "ごめん→「失礼いたしました」")
        allow(SearchLog).to receive(:create).and_return(SearchLog.new)
        perform_request
      end

      it "still returns OK" do
        expect(response).to have_http_status(:ok)
      end

      it "still shows converted text" do
        expect(response.body).to include("失礼いたしました")
      end
    end
  end

  describe "POST /rephrases" do
    subject(:perform_request) { post rephrases_path, params: params }

    let(:params) do
      {
        rephrase: {
          content: "確認お願いします",
          scene: "",
          target: "",
          context: ""
        }
      }
    end

    before do
      allow(PhraseConverterService).to receive(:call).and_return(
        {
          result_text: "ご確認ください",
          safety_mode_applied: false,
          hit_type: :none
        }
      )
    end

    it "creates at least three rephrase/search log candidates" do
      expect { perform_request }
        .to change(Rephrase, :count).by(3)
        .and change(SearchLog, :count).by(3)
    end

    it "redirects to rephrases index" do
      perform_request

      expect(response).to redirect_to(rephrases_path)
    end

    context "when mock conversion is enabled for suffix cleanup" do
      let(:params) do
        {
          rephrase: {
            content: "これやって",
            scene: "",
            target: "",
            context: ""
          }
        }
      end

      before do
        allow(PhraseConverterService).to receive(:call).and_raise("should not be called")
        perform_request
      end

      it "includes business template" do
        expect(created_candidates_for("これやって")).to include("これの件ですが、何卒よろしくお願い申し上げます。")
      end

      it "includes polite template" do
        expect(created_candidates_for("これやって")).to include("これにつきまして、ご確認をお願いできますでしょうか？")
      end

      it "includes casual template" do
        expect(created_candidates_for("これやって")).to include("これの件ですが、よろしくね！")
      end
    end

    context "when mock conversion is enabled for short input" do
      let(:params) do
        {
          rephrase: {
            content: "あ",
            scene: "",
            target: "",
            context: ""
          }
        }
      end

      before do
        allow(PhraseConverterService).to receive(:call).and_raise("should not be called")
        perform_request
      end

      it "includes fallback business template" do
        expect(created_candidates_for("あ")).to include("ご依頼の件ですが、何卒よろしくお願い申し上げます。")
      end

      it "includes fallback polite template" do
        expect(created_candidates_for("あ")).to include("ご依頼につきまして、ご確認をお願いできますでしょうか？")
      end

      it "includes fallback casual template" do
        expect(created_candidates_for("あ")).to include("ご依頼の件ですが、よろしくね！")
      end
    end

    context "when mock conversion is enabled for vocabulary replacement" do
      let(:params) do
        {
          rephrase: {
            content: "早く見て教えて",
            scene: "",
            target: "",
            context: ""
          }
        }
      end

      before do
        allow(PhraseConverterService).to receive(:call).and_raise("should not be called")
        perform_request
      end

      it "includes replaced business template" do
        expect(created_candidates_for("早く見て教えて")).to include(
          "至急ご確認ご教示の件ですが、何卒よろしくお願い申し上げます。"
        )
      end

      it "includes replaced polite template" do
        expect(created_candidates_for("早く見て教えて")).to include(
          "至急ご確認ご教示につきまして、ご確認をお願いできますでしょうか？"
        )
      end

      it "includes replaced casual template" do
        expect(created_candidates_for("早く見て教えて")).to include("至急ご確認ご教示の件ですが、よろしくね！")
      end
    end
  end

  def created_candidates_for(query)
    SearchLog.where(query: query).order(created_at: :desc).limit(3).pluck(:converted_text)
  end
end
