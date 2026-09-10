class CreateOrderTool < ApplicationTool
  description "Create a new order for a customer with one or more line items. " \
              "This writes to the database and decrements product stock — " \
              "confirm the details with the user before calling it."

  annotations(
    destructive_hint: true,
    idempotent_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:customer_name).filled(:string).description("Customer's full name")
    required(:customer_email).filled(:string).description("Customer's email address")
    required(:line_items).array(:hash).description("List of { sku, quantity } to order") do
      required(:sku).filled(:string).description("Product SKU")
      required(:quantity).filled(:integer).description("Quantity to order")
    end
  end

  def call(customer_name:, customer_email:, line_items:)
    order = nil

    ActiveRecord::Base.transaction do
      order = Order.create!(customer_name: customer_name, customer_email: customer_email, status: "pending")

      line_items.each do |line|
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

    { order_id: order.id, status: order.status, total: order.total }
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    { error: e.message }
  end
end
