require "rails_helper"

RSpec.describe Order do
  let(:valid_attributes) do
    { customer_name: "Alice", customer_email: "alice@example.com", status: "pending" }
  end

  it "is valid with valid attributes" do
    expect(Order.new(valid_attributes)).to be_valid
  end

  it "requires a customer name" do
    order = Order.new(valid_attributes.merge(customer_name: nil))
    expect(order).not_to be_valid
    expect(order.errors[:customer_name]).to be_present
  end

  it "requires a customer email" do
    order = Order.new(valid_attributes.merge(customer_email: nil))
    expect(order).not_to be_valid
    expect(order.errors[:customer_email]).to be_present
  end

  it "accepts each defined status" do
    Order::STATUSES.each do |status|
      order = Order.new(valid_attributes.merge(status: status))
      expect(order).to be_valid
    end
  end

  it "rejects a status outside the defined list" do
    order = Order.new(valid_attributes.merge(status: "shipped"))
    expect(order).not_to be_valid
    expect(order.errors[:status]).to be_present
  end

  describe "#total_cents and #total" do
    it "sums quantity times unit price across all line items" do
      product = Product.create!(title: "Widget", sku: "WID-1", price_cents: 1000, stock_quantity: 10)
      other_product = Product.create!(title: "Gadget", sku: "GAD-1", price_cents: 500, stock_quantity: 10)
      order = Order.create!(valid_attributes)
      order.order_items.create!(product: product, quantity: 2, unit_price_cents: 1000)
      order.order_items.create!(product: other_product, quantity: 3, unit_price_cents: 500)

      expect(order.total_cents).to eq(3500)
      expect(order.total).to eq(35.0)
    end

    it "is zero for an order with no line items" do
      order = Order.create!(valid_attributes)
      expect(order.total_cents).to eq(0)
      expect(order.total).to eq(0.0)
    end
  end

  describe "deletion" do
    it "destroys its order items along with the order" do
      product = Product.create!(title: "Widget", sku: "WID-1", price_cents: 1000, stock_quantity: 10)
      order = Order.create!(valid_attributes)
      order.order_items.create!(product: product, quantity: 1, unit_price_cents: 1000)

      expect { order.destroy }.to change(OrderItem, :count).by(-1)
    end
  end
end
