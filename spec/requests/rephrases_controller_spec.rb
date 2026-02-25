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

      created_candidates = SearchLog.order(created_at: :desc).limit(3).pluck(:converted_text)
      expect(created_candidates.size).to eq(3)
      expect(created_candidates.uniq.size).to eq(3)
    end

    it "redirects to rephrases index" do
      perform_request

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(rephrases_path)
    end

    context "when mock conversion is enabled" do
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
      end

      it "applies regex-based cleanup and creates three templated candidates" do
        perform_request

        created_candidates = SearchLog.where(query: "これやって").order(created_at: :desc).limit(3).pluck(:converted_text)
        expect(created_candidates).to include("これの件ですが、何卒よろしくお願い申し上げます。")
        expect(created_candidates).to include("これにつきまして、ご確認をお願いできますでしょうか？")
        expect(created_candidates).to include("これの件ですが、よろしくね！")
      end

      context "when input is too short" do
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

        it "uses fallback templates" do
          perform_request

          created_candidates = SearchLog.where(query: "あ").order(created_at: :desc).limit(3).pluck(:converted_text)
          expect(created_candidates).to include("ご依頼の件ですが、何卒よろしくお願い申し上げます。")
          expect(created_candidates).to include("ご依頼につきまして、ご確認をお願いできますでしょうか？")
          expect(created_candidates).to include("ご依頼の件ですが、よろしくね！")
        end
      end

      context "when input includes replaceable words" do
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

        it "applies vocabulary replacements before suffix cleanup" do
          perform_request

          created_candidates = SearchLog.where(query: "早く見て教えて").order(created_at: :desc).limit(3).pluck(:converted_text)
          expect(created_candidates).to include("至急ご確認ご教示の件ですが、何卒よろしくお願い申し上げます。")
          expect(created_candidates).to include("至急ご確認ご教示につきまして、ご確認をお願いできますでしょうか？")
          expect(created_candidates).to include("至急ご確認ご教示の件ですが、よろしくね！")
        end
      end
    end
  end
end
