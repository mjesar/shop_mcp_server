# Lets a client send the shared token as `X-Api-Key: <token>` instead of
# `Authorization: Bearer <token>`. The mcp gem only reads the Authorization header,
# so this copies the key there and the token is still checked by McpTokenVerifier.
class McpApiKeyHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    api_key = env["HTTP_X_API_KEY"]
    env["HTTP_AUTHORIZATION"] = "Bearer #{api_key}" if api_key.present? && env["HTTP_AUTHORIZATION"].blank?

    @app.call(env)
  end
end
