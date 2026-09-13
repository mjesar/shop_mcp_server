class GetProductTool < MCP::Tool
  title "Get Product"
  description "Get full details for a single product by its ID or SKU."
  input_schema(
    properties: {
      id: { type: "integer" },
      sku: { type: "string" }
    },
  )
  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false,
  )

  class << self
    def call(id: nil, sku: nil, server_context:)
      product = if id
                  Product.find_by(id: id)
      elsif sku
                  Product.find_by(sku: sku)
      end

      return MCP::Tool::Response.new([ { type: "text", text: JSON.generate({ error: "Provide either id or sku" }) } ], error: true) if id.nil? && sku.nil?
      return MCP::Tool::Response.new([ { type: "text", text: JSON.generate({ error: "Product not found" }) } ], error: true) unless product

      result = {
        id: product.id,
        title: product.title,
        sku: product.sku,
        description: product.description,
        price: product.price,
        stock_quantity: product.stock_quantity,
        low_stock: product.low_stock?
      }

      MCP::Tool::Response.new([ { type: "text", text: JSON.generate(result) } ])
    end
  end
end
