class GetOrderTool < ApplicationTool
  description "Get full details for a single order, including its line items."

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Order ID")
  end

  def call(id:)
    order = Order.find_by(id: id)
    return { error: "Order not found" } unless order

    {
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
  end
end
