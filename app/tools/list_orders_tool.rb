class ListOrdersTool < MCP::Tool
  title "List Order Tool"
  description "List recent orders, optionally filtered by status " \
              "(pending, paid, fulfilled, cancelled)."

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      status: { type: "string", description: "Filter by exact order status" },
      limit: { type: "integer", description: "Max number of orders to return (default 10)" }
    },
  )

  class << self
    def call(status: nil, limit: 10, server_context:)
      orders = Order.recent.limit(limit)
      orders = orders.with_status(status) if status.present?

      results = orders.map do |order|
        {
          id: order.id,
          customer_name: order.customer_name,
          status: order.status,
          item_count: order.order_items.sum(:quantity),
          total: order.total,
          created_at: order.created_at.iso8601
        }
      end
      MCP::Tool::Response.new([ { type: "text", text: JSON.generate(results) } ])
    end
  end
end
