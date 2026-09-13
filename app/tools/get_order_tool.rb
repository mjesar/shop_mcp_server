class GetOrderTool < MCP::Tool
  title "Get Order Tool"
  description "Get full details for a single order, including its line items."

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      id: { type: "integer", description: "Order ID" }
    },
    required: [ "id" ]
  )

  class << self
    def call(id:, server_context:)
      order = Order.find_by(id: id)
      return MCP::Tool::Response.new([ { type: "text", text: JSON.generate({ error: "Order not found" }) } ], error: true) unless order

     results =  {
        id: order.id,
        customer_name: order.customer_name,
        customer_email: order.customer_email,
        status: order.status,
        total: order.total,
        created_at: order.created_at.iso8601,
        line_items: order.order_items.map do |item|
          {
            product_title: item.product.title,
            sku: item.product.sku,
            quantity: item.quantity,
            unit_price: item.unit_price_cents / 100.0,
            subtotal: item.subtotal_cents / 100.0
          }
        end
      }

      MCP::Tool::Response.new([ { type: "text", text: JSON.generate(results)  } ])
    end
  end
end
