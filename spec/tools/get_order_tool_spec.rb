require "rails_helper"

RSpec.describe GetOrderTool do
  let!(:product) { Product.create!(title: "Widget", sku: "WID-1", price_cents: 1000, stock_quantity: 10) }
  let!(:order) do
    Order.create!(customer_name: "Alice", customer_email: "alice@example.com", status: "paid")
  end

  before do
    order.order_items.create!(product: product, quantity: 3, unit_price_cents: 1000)
  end

  it "returns full order details with nested line items" do
    response = described_class.call(id: order.id, server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(false)
    expect(result["id"]).to eq(order.id)
    expect(result["customer_name"]).to eq("Alice")
    expect(result["status"]).to eq("paid")
    expect(result["total"]).to eq(30.0)
    expect(result["line_items"]).to eq([
      {
        "product_title" => "Widget",
        "sku" => "WID-1",
        "quantity" => 3,
        "unit_price" => 10.0,
        "subtotal" => 30.0
      }
    ])
  end

  it "errors when the order cannot be found" do
    response = described_class.call(id: order.id + 1, server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(true)
    expect(result["error"]).to eq("Order not found")
  end
end
