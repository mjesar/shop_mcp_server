class CreateOrderTool < MCP::Tool
  title "Create Order Tool"
  description "Create a new order for a customer with one or more line items. " \
              "This writes to the database and decrements product stock — " \
              "confirm the details with the user before calling it."

  annotations(
    destructive_hint: true,
    idempotent_hint: false,
    open_world_hint: false
  )

  input_schema(
    properties: {
      customer_name: { type: "string", description: "Customer's full name" },
      customer_email: { type: "string", description: "Customer's email address" },
      line_items: {
        type: "array",
        description: "List of { sku, quantity } to order",
        items: {
          type: "object",
          properties: {
            sku: { type: "string", description: "Product SKU" },
            quantity: { type: "integer", description: "Quantity to order" }
          },
          required: [ "sku", "quantity" ]
        }
      }
    },
    required: [ "customer_name", "customer_email", "line_items" ]
  )

  class << self
    def call(customer_name:, customer_email:, line_items:, server_context:)
      order = nil

      begin
        ActiveRecord::Base.transaction do
          order = Order.create!(customer_name: customer_name, customer_email: customer_email, status: "pending")

          line_items.each do |line|
            line = line.symbolize_keys
            product = Product.find_by(sku: line[:sku])
            raise ArgumentError, "Unknown SKU: #{line[:sku]}" unless product
            raise ArgumentError, "Insufficient stock for #{product.sku}" if product.stock_quantity < line[:quantity]

            order.order_items.create!(
              product: product,
              quantity: line[:quantity],
              unit_price_cents: product.price_cents
            )
            product.decrement!(:stock_quantity, line[:quantity])
          end
        end

        results = { order_id: order.id, status: order.status, total: order.total }
        MCP::Tool::Response.new([ { type: "text", text: JSON.generate(results) } ])
      rescue ActiveRecord::RecordInvalid, ArgumentError => e
        MCP::Tool::Response.new([ { type: "text", text: JSON.generate({ error: e.message }) } ], error: true)
      end
    end
  end
end
