# Checks the shared bearer token on every request to /mcp. The mcp gem calls
# #verify with the token from the Authorization header, and treats nil as a rejection.
class McpTokenVerifier < MCP::Server::OAuth::TokenVerifier
  class MissingTokenError < StandardError; end

  # Returns a verifier when a token is set, and nil when the server may stay open.
  # Raises when the server can be reached from outside but has no token, so it can
  # never run open by accident. Tests ignore NGROK_HOST so they do not depend on .env.
  def self.from_env(env: ENV, rails_env: Rails.env)
    token = env["MCP_AUTH_TOKEN"].presence
    return new(token) if token

    reachable_from_outside = rails_env == "production" || (rails_env != "test" && env["NGROK_HOST"].present?)
    return unless reachable_from_outside

    raise MissingTokenError,
      "MCP_AUTH_TOKEN must be set in production or when NGROK_HOST is set. Generate one with: bin/rails secret"
  end

  def initialize(expected_token)
    @expected_token = expected_token
  end

  def verify(token)
    return unless ActiveSupport::SecurityUtils.secure_compare(token, @expected_token)

    MCP::Server::OAuth::AccessToken.new(token: token, client_id: "shared-token")
  end
end
