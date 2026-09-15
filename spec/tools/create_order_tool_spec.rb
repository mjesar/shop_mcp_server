require "rails_helper"

RSpec.describe CreateOrderTool do
  let!(:widget) { Product.create!(title: "Widget", sku: "WID-1", price_cents: 1000, stock_quantity: 10) }
  let!(:gadget) { Product.create!(title: "Gadget", sku: "GAD-1", price_cents: 500, stock_quantity: 2) }

  it "creates the order, creates its line items, and decrements stock" do
    response = described_class.call(
      customer_name: "Alice",
      customer_email: "alice@example.com",
      line_items: [
        { "sku" => "WID-1", "quantity" => 2 },
        { "sku" => "GAD-1", "quantity" => 1 }
      ],
      server_context: {}
    )
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(false)

    order = Order.find(result["order_id"])
    expect(order.status).to eq("pending")
    expect(order.order_items.count).to eq(2)
    expect(result["total"]).to eq(25.0)

    expect(widget.reload.stock_quantity).to eq(8)
    expect(gadget.reload.stock_quantity).to eq(1)
  end

  it "rolls back the whole order when a line item has an unknown sku" do
    expect {
      response = described_class.call(
        customer_name: "Bob",
        customer_email: "bob@example.com",
        line_items: [
          { "sku" => "WID-1", "quantity" => 2 },
          { "sku" => "NOPE", "quantity" => 1 }
        ],
        server_context: {}
      )
      result = JSON.parse(response.content.first[:text])

      expect(response.error?).to eq(true)
      expect(result["error"]).to eq("Unknown SKU: NOPE")
    }.to change(Order, :count).by(0)
      .and change(OrderItem, :count).by(0)

    expect(widget.reload.stock_quantity).to eq(10)
  end

  it "rolls back the whole order when a line item requests more than the available stock" do
    expect {
      response = described_class.call(
        customer_name: "Carol",
        customer_email: "carol@example.com",
        line_items: [
          { "sku" => "WID-1", "quantity" => 2 },
          { "sku" => "GAD-1", "quantity" => 5 }
        ],
        server_context: {}
      )
      result = JSON.parse(response.content.first[:text])

      expect(response.error?).to eq(true)
      expect(result["error"]).to eq("Insufficient stock for GAD-1")
    }.to change(Order, :count).by(0)
      .and change(OrderItem, :count).by(0)

    expect(widget.reload.stock_quantity).to eq(10)
    expect(gadget.reload.stock_quantity).to eq(2)
  end
end
