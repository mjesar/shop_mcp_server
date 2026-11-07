# Routes load lazily outside production, so check here to fail at boot instead of
# on the first request.
Rails.application.config.after_initialize do
  McpTokenVerifier.from_env
end
