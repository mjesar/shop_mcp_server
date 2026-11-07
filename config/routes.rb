# frozen_string_literal: true

server = MCP::Server.new(
  name: "shop-mcp-server",
  title: "Shop MCP Server",
  version: "1.0.0",
  tools: [ GetProductTool, ListProductsTool, CheckInventoryTool, ListOrdersTool, GetOrderTool, CreateOrderTool, SemanticSearchProductsTool ],
  resources: [ ProductCatalogResource, LowStockResource ],
  prompts: [ InventoryCheckPrompt ]
)

ngrok_url = ENV.fetch("NGROK_HOST", nil)
ngrok_host = ngrok_url && URI(ngrok_url).host
app_host = ENV["APP_HOST"].presence

transport = MCP::Server::Transports::StreamableHTTPTransport.new(
  server,
  allowed_hosts: [ ngrok_host, app_host ].compact,
  allowed_origins: [ ngrok_url, app_host && "https://#{app_host}" ].compact,
  token_verifier: McpTokenVerifier.from_env,
)

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount(transport => "/mcp")
end
