class ListProductsTool < MCP::Tool
  title "List Products Tool"
  description "List products in the store catalog, optionally filtered by " \
              "a title search term and/or stock availability."

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      search: { type: "string", description: "Case-insensitive substring to match against product titles" },
      in_stock_only: { type: "boolean", description: "If true, only return products with stock_quantity > 0" },
      limit: { type: "integer", description: "Max number of products to return (default 20)" }
    },
  )

  class << self
    def call(search: nil, in_stock_only: false, limit: 20, server_context:)
      products = Product.all
      products = products.search_by_title(search) if search.present?
      products = products.in_stock if in_stock_only
      products = products.order(:title).limit(limit)

      results = products.map do |product|
        {
          id: product.id,
          title: product.title,
          sku: product.sku,
          price: product.price,
          stock_quantity: product.stock_quantity
        }
      end

      MCP::Tool::Response.new([ { type: "text", text: JSON.generate(results) } ])
    end
  end
end
