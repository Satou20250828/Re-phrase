require "rails_helper"

RSpec.describe PhraseConverterService do
  describe "#call" do
    subject(:result) do
      described_class.new(
        query: query,
        category_id: category_id,
        scene: scene,
        target: target,
        context: context
      ).call
    end

    let(:query) { "ご確認お願いします" }
    let(:category_id) { nil }
    let(:scene) { "職場" }
    let(:target) { "目上" }
    let(:context) { "依頼" }

    context "when mock mode is enabled" do
      before { stub_phrase_converter_env(mock: true, api_key: "dummy") }

      it "does not instantiate OpenAI client and returns fallback text" do
        expect(OpenAI::Client).not_to receive(:new) if defined?(OpenAI::Client)

        expect(result).to include(
          result_text: query,
          safety_mode_applied: true,
          hit_type: :none
        )
      end
    end

    context "when API mode is enabled and OpenAI returns success response" do
      let(:api_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "1. [短文] ご確認をお願いいたします。\n2. [標準] ご確認いただけますと幸いです。\n3. [フォーマル] ご確認のほどお願い申し上げます。"
              }
            }
          ]
        }
      end

      before do
        stub_phrase_converter_env(mock: false, api_key: "test-openai-key")
        stub_openai_client(chat_response: api_response)
      end

      it "extracts and formats converted variants from API response" do
        expect(result[:result_text]).to include("1. [短文] ご確認をお願いいたします。")
        expect(result[:result_text]).to include("2. [標準] ご確認いただけますと幸いです。")
        expect(result[:result_text]).to include("3. [フォーマル] ご確認のほどお願い申し上げます。")
        expect(result[:safety_mode_applied]).to be(false)
        expect(result[:hit_type]).to eq(:none)
      end
    end

    shared_examples "falls back safely when AI generation fails" do |error|
      before do
        stub_phrase_converter_env(mock: false, api_key: "test-openai-key")
        stub_openai_client(chat_error: error)
      end

      it "logs warning and returns fallback result" do
        expect(Rails.logger).to receive(:warn).with(include("AI generation failed"))

        expect(result).to include(
          result_text: query,
          safety_mode_applied: true,
          hit_type: :none
        )
      end
    end

    context "when API returns 401 unauthorized" do
      include_examples "falls back safely when AI generation fails", StandardError.new("401 Unauthorized")
    end

    context "when API returns 429 rate limit" do
      include_examples "falls back safely when AI generation fails", StandardError.new("429 Too Many Requests")
    end

    context "when API request times out" do
      include_examples "falls back safely when AI generation fails", Timeout::Error.new("execution expired")
    end

    context "when API responds successfully but content is empty" do
      before do
        stub_phrase_converter_env(mock: false, api_key: "test-openai-key")
        stub_openai_client(chat_response: { "choices" => [{ "message" => { "content" => "" } }] })
      end

      it "falls back to local result safely" do
        expect(result).to include(
          result_text: query,
          safety_mode_applied: true,
          hit_type: :none
        )
      end
    end

    context "when query is nil" do
      let(:query) { nil }

      before { stub_phrase_converter_env(mock: true, api_key: "dummy") }

      it "returns empty fallback text safely" do
        expect(result).to include(
          result_text: "",
          safety_mode_applied: true,
          hit_type: :none
        )
      end
    end

    context "when query is empty string" do
      let(:query) { "" }

      before { stub_phrase_converter_env(mock: true, api_key: "dummy") }

      it "returns empty fallback text safely" do
        expect(result).to include(
          result_text: "",
          safety_mode_applied: true,
          hit_type: :none
        )
      end
    end
  end
end
