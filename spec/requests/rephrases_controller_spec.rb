require "rails_helper"

RSpec.describe "RephrasesController", type: :request do
  describe "GET /rephrases" do
    it "returns ok and renders recent history" do
      create(:search_log, query: "確認お願いします", converted_text: "ご確認をお願いいたします。")

      get rephrases_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("履歴")
      expect(response.body).to include("確認お願いします")
    end
  end

  describe "POST /rephrases" do
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

    context "when valid" do
      before do
        stub_const("RephrasesController::MIN_REPHRASE_CANDIDATES", 1)
        allow(PhraseConverterService).to receive(:call).and_return(
          {
            result_text: "ご確認をお願いいたします。",
            safety_mode_applied: false,
            hit_type: :none
          }
        )
      end

      it "creates one SearchLog and returns turbo stream result" do
        expect do
          post rephrases_path(format: :turbo_stream), params: params
        end.to change(SearchLog, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
        expect(response.body).to include("<turbo-stream")
        expect(response.body).to include('target="rephrase_result"')
        expect(response.body).to include("提案結果")
      end
    end

    context "when invalid" do
      it "does not create SearchLog and returns turbo stream errors" do
        invalid_params = {
          rephrase: {
            content: " ",
            scene: "",
            target: "",
            context: ""
          }
        }

        expect do
          post rephrases_path(format: :turbo_stream), params: invalid_params
        end.not_to change(SearchLog, :count)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
        expect(response.body).to include("<turbo-stream")
        expect(response.body).to include('target="error_modal_container"')
        expect(response.body).to include("入力文が空です")
      end
    end
  end

  describe "DELETE /rephrases/history/:id" do
    it "deletes target history and returns turbo stream remove action" do
      search_log = create(:search_log)

      expect do
        delete rephrase_history_path(search_log, format: :turbo_stream)
      end.to change(SearchLog, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include("<turbo-stream")
      expect(response.body).to include('action="remove"')
      expect(response.body).to include(%(target="#{ActionView::RecordIdentifier.dom_id(search_log)}"))
    end
  end
end
