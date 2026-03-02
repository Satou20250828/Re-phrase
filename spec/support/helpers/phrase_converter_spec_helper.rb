# Shared test helpers for PhraseConverterService specs.
module PhraseConverterSpecHelper
  def stub_phrase_converter_env(mock:, api_key: nil, model: "gpt-4o-mini")
    stub_phrase_converter_env_defaults(mock: mock, model: model)
    stub_phrase_converter_api_key(api_key)
  end

  def stub_openai_client(chat_response: nil, chat_error: nil)
    ensure_openai_client_constant!

    client_double = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(client_double)

    if chat_error
      allow(client_double).to receive(:chat).and_raise(chat_error)
    else
      allow(client_double).to receive(:chat).and_return(chat_response)
    end

    client_double
  end

  private

  def stub_phrase_converter_env_defaults(mock:, model:)
    stub_env_fallbacks
    stub_phrase_converter_fetch_values(mock: mock, model: model)
  end

  def stub_env_fallbacks
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
  end

  def stub_phrase_converter_fetch_values(mock:, model:)
    allow(ENV).to receive(:fetch)
      .with("REPHRASE_USE_MOCK", true)
      .and_return(mock.to_s)
    allow(ENV).to receive(:fetch)
      .with("OPENAI_MODEL", "gpt-4o-mini")
      .and_return(model)
  end

  def stub_phrase_converter_api_key(api_key)
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(api_key)
    return if api_key.blank?

    allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return(api_key)
  end

  def ensure_openai_client_constant!
    stub_const("OpenAI", Module.new) unless defined?(OpenAI)
    return if defined?(OpenAI::Client)

    stub_const("OpenAI::Client", Class.new do
      def initialize(*); end

      def chat(*); end
    end)
  end
end
