require "rails_helper"

RSpec.describe McpApiKeyHeader do
  let(:server) { MCP::Server.new(name: "test-server") }
  let(:transport) do
    MCP::Server::Transports::StreamableHTTPTransport.new(server, token_verifier: McpTokenVerifier.new("right-token"))
  end

  after { transport.close }

  def initialize_request(headers = {})
    body = {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "spec", version: "1.0" } }
    }.to_json

    Rack::MockRequest.new(described_class.new(transport)).post(
      "/",
      { input: body, "HTTP_HOST" => "localhost", "CONTENT_TYPE" => "application/json",
        "HTTP_ACCEPT" => "application/json, text/event-stream" }.merge(headers)
    )
  end

  it "lets the request through when the api key is the right token" do
    expect(initialize_request("HTTP_X_API_KEY" => "right-token").status).to eq(200)
  end

  it "answers 401 when the api key is wrong" do
    expect(initialize_request("HTTP_X_API_KEY" => "wrong-token").status).to eq(401)
  end

  it "answers 401 when neither header is sent" do
    expect(initialize_request.status).to eq(401)
  end

  it "still accepts the Authorization header" do
    expect(initialize_request("HTTP_AUTHORIZATION" => "Bearer right-token").status).to eq(200)
  end

  it "does not let a right api key rescue a wrong Authorization header" do
    response = initialize_request("HTTP_AUTHORIZATION" => "Bearer wrong-token", "HTTP_X_API_KEY" => "right-token")

    expect(response.status).to eq(401)
  end
end
