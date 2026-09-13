# frozen_string_literal: true

server = MCP::Server.new(
  name: "shop-mcp-server",
  title: "Shop MCP Server",
  version: "1.0.0",
  tools: [ GetProductTool, ListProductsTool, CheckInventoryTool, ListOrdersTool, GetOrderTool, CreateOrderTool ],
  resources: [ ProductCatalogResource, LowStockResource ],
)

transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount(transport => "/mcp")
end
