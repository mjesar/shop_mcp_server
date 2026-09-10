class ListOrdersTool < ApplicationTool
  description "List recent orders, optionally filtered by status " \
              "(pending, paid, fulfilled, cancelled)."

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:status).filled(:string).description("Filter by exact order status")
    optional(:limit).filled(:integer).description("Max number of orders to return (default 10)")
  end

  def call(status: nil, limit: 10)
    scope = Order.recent.limit(limit)
    scope = scope.with_status(status) if status.present?

    scope.map do |order|
      {
        id: order.id,
        customer_name: order.customer_name,
        status: order.status,
        item_count: order.order_items.sum(:quantity),
        total: order.total,
        created_at: order.created_at.iso8601
      }
    end
  end
end
