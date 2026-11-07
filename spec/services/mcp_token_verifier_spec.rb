require "rails_helper"

RSpec.describe McpTokenVerifier do
  describe "#verify" do
    let(:verifier) { described_class.new("right-token") }

    it "accepts the expected token" do
      expect(verifier.verify("right-token").token).to eq("right-token")
    end

    it "rejects any other token" do
      expect(verifier.verify("wrong-token")).to be_nil
    end
  end

  describe ".from_env" do
    it "returns a verifier whenever a token is set" do
      verifier = described_class.from_env(env: { "MCP_AUTH_TOKEN" => "secret" }, rails_env: "development")

      expect(verifier).to be_a(described_class)
    end

    it "stays open for plain local development" do
      expect(described_class.from_env(env: {}, rails_env: "development")).to be_nil
    end

    it "ignores NGROK_HOST in the test environment" do
      env = { "NGROK_HOST" => "https://abc.ngrok-free.app" }

      expect(described_class.from_env(env: env, rails_env: "test")).to be_nil
    end

    it "refuses to run in production without a token" do
      expect { described_class.from_env(env: {}, rails_env: "production") }
        .to raise_error(described_class::MissingTokenError)
    end

    it "refuses to run behind a tunnel without a token" do
      env = { "NGROK_HOST" => "https://abc.ngrok-free.app" }

      expect { described_class.from_env(env: env, rails_env: "development") }
        .to raise_error(described_class::MissingTokenError)
    end

    it "treats a blank token as missing" do
      expect { described_class.from_env(env: { "MCP_AUTH_TOKEN" => " " }, rails_env: "production") }
        .to raise_error(described_class::MissingTokenError)
    end
  end

  describe "as the token verifier of the MCP transport" do
    let(:server) { MCP::Server.new(name: "test-server") }
    let(:transport) do
      MCP::Server::Transports::StreamableHTTPTransport.new(server, token_verifier: described_class.new("right-token"))
    end

    after { transport.close }

    def initialize_request(headers = {})
      body = {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "spec", version: "1.0" } }
      }.to_json

      Rack::MockRequest.new(transport).post(
        "/",
        { input: body, "HTTP_HOST" => "localhost", "CONTENT_TYPE" => "application/json",
          "HTTP_ACCEPT" => "application/json, text/event-stream" }.merge(headers)
      )
    end

    it "answers 401 with a Bearer challenge when no token is sent" do
      response = initialize_request

      expect(response.status).to eq(401)
      expect(response.headers["WWW-Authenticate"]).to start_with("Bearer")
    end

    it "answers 401 when the token is wrong" do
      expect(initialize_request("HTTP_AUTHORIZATION" => "Bearer wrong-token").status).to eq(401)
    end

    it "lets the request through when the token is right" do
      expect(initialize_request("HTTP_AUTHORIZATION" => "Bearer right-token").status).to eq(200)
    end
  end
end
