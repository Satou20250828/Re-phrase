require "rails_helper"

RSpec.describe PhraseConverterService do
  describe "#call" do
    before do
      stub_const("OpenAI::Client", Class.new do
        def initialize(*); end

        def chat(*); end
      end)
    end

    let(:service) do
      described_class.new(
        query: query,
        category_id: category_id,
        scene: scene,
        target: target,
        context: context
      )
    end
    subject(:result) { service.call }

    let(:query) { "ご確認お願いします" }
    let(:category_id) { nil }
    let(:scene) { "職場" }
    let(:target) { "目上" }
    let(:context) { "依頼" }

    def stub_service_env(mock:, api_key: nil, model: "gpt-4o-mini")
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:[]).and_call_original

      allow(ENV).to receive(:fetch).with("REPHRASE_USE_MOCK", true).and_return(mock.to_s)
      allow(ENV).to receive(:fetch).with("OPENAI_MODEL", "gpt-4o-mini").and_return(model)

      if api_key.present?
        allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return(api_key)
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(api_key)
      else
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)
      end
    end

    context "when mock mode is enabled" do
      before do
        stub_service_env(mock: true, api_key: "dummy")
      end

      it "does not instantiate OpenAI client and returns fallback text" do
        expect(OpenAI::Client).not_to receive(:new)

        expect(result[:result_text]).to eq(query)
        expect(result[:safety_mode_applied]).to be(true)
        expect(result[:hit_type]).to eq(:none)
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
        stub_service_env(mock: false, api_key: "test-openai-key")
        allow(service).to receive(:openai_available?).and_return(true)
        allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("test-openai-key")
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(api_response)
      end

      it "extracts and formats converted variants from API response" do
        expect(Rails.logger).not_to receive(:warn)

        expect(result[:result_text]).to include("1. [短文] ご確認をお願いいたします。")
        expect(result[:result_text]).to include("2. [標準] ご確認いただけますと幸いです。")
        expect(result[:result_text]).to include("3. [フォーマル] ご確認のほどお願い申し上げます。")
        expect(result[:safety_mode_applied]).to be(false)
        expect(result[:hit_type]).to eq(:none)
      end
    end

    context "when API returns 401 unauthorized" do
      let(:error) { Class.new(StandardError).new("401 Unauthorized") }

      before do
        stub_service_env(mock: false, api_key: "invalid-key")
        allow(service).to receive(:openai_available?).and_return(true)
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(error)
      end

      it "logs warning and falls back safely" do
        expect(Rails.logger).to receive(:warn).with(include("AI generation failed"))

        expect(result[:result_text]).to eq(query)
        expect(result[:safety_mode_applied]).to be(true)
        expect(result[:hit_type]).to eq(:none)
      end
    end

    context "when API returns 429 rate limit" do
      let(:error) { Class.new(StandardError).new("429 Too Many Requests") }

      before do
        stub_service_env(mock: false, api_key: "test-openai-key")
        allow(service).to receive(:openai_available?).and_return(true)
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(error)
      end

      it "handles the error and returns fallback result" do
        expect(Rails.logger).to receive(:warn).with(include("AI generation failed"))

        expect(result[:result_text]).to eq(query)
        expect(result[:safety_mode_applied]).to be(true)
        expect(result[:hit_type]).to eq(:none)
      end
    end

    context "when API request times out" do
      let(:error) { Timeout::Error.new("execution expired") }

      before do
        stub_service_env(mock: false, api_key: "test-openai-key")
        allow(service).to receive(:openai_available?).and_return(true)
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(error)
      end

      it "handles timeout and returns fallback result" do
        expect(Rails.logger).to receive(:warn).with(include("AI generation failed"))

        expect(result[:result_text]).to eq(query)
        expect(result[:safety_mode_applied]).to be(true)
        expect(result[:hit_type]).to eq(:none)
      end
    end

    context "when API responds successfully but content is empty" do
      let(:api_response) { { "choices" => [{ "message" => { "content" => "" } }] } }

      before do
        stub_service_env(mock: false, api_key: "test-openai-key")
        allow(service).to receive(:openai_available?).and_return(true)
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(api_response)
      end

      it "falls back to local result safely" do
        expect(result[:result_text]).to eq(query)
        expect(result[:safety_mode_applied]).to be(true)
        expect(result[:hit_type]).to eq(:none)
      end
    end

    context "when query is nil" do
      let(:query) { nil }

      before do
        stub_service_env(mock: true, api_key: "dummy")
      end

      it "returns empty fallback text safely" do
        expect(result[:result_text]).to eq("")
        expect(result[:safety_mode_applied]).to be(true)
        expect(result[:hit_type]).to eq(:none)
      end
    end

    context "when query is empty string" do
      let(:query) { "" }

      before do
        stub_service_env(mock: true, api_key: "dummy")
      end

      it "returns empty fallback text safely" do
        expect(result[:result_text]).to eq("")
        expect(result[:safety_mode_applied]).to be(true)
        expect(result[:hit_type]).to eq(:none)
      end
    end
  end
end
