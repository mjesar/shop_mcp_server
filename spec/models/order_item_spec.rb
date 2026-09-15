require "rails_helper"

RSpec.describe OrderItem do
  let!(:product) { Product.create!(title: "Widget", sku: "WID-1", price_cents: 1000, stock_quantity: 10) }
  let!(:order) { Order.create!(customer_name: "Alice", customer_email: "alice@example.com", status: "pending") }

  let(:valid_attributes) { { order: order, product: product, quantity: 2, unit_price_cents: 1000 } }

  it "is valid with valid attributes" do
    expect(OrderItem.new(valid_attributes)).to be_valid
  end

  it "requires an order" do
    item = OrderItem.new(valid_attributes.merge(order: nil))
    expect(item).not_to be_valid
    expect(item.errors[:order]).to be_present
  end

  it "requires a product" do
    item = OrderItem.new(valid_attributes.merge(product: nil))
    expect(item).not_to be_valid
    expect(item.errors[:product]).to be_present
  end

  it "rejects a quantity of zero" do
    item = OrderItem.new(valid_attributes.merge(quantity: 0))
    expect(item).not_to be_valid
    expect(item.errors[:quantity]).to be_present
  end

  it "rejects a negative quantity" do
    item = OrderItem.new(valid_attributes.merge(quantity: -1))
    expect(item).not_to be_valid
    expect(item.errors[:quantity]).to be_present
  end

  it "rejects a negative unit price" do
    item = OrderItem.new(valid_attributes.merge(unit_price_cents: -1))
    expect(item).not_to be_valid
    expect(item.errors[:unit_price_cents]).to be_present
  end

  it "allows a unit price of zero" do
    item = OrderItem.new(valid_attributes.merge(unit_price_cents: 0))
    expect(item).to be_valid
  end

  describe "#subtotal_cents" do
    it "multiplies quantity by unit price" do
      item = OrderItem.new(valid_attributes.merge(quantity: 3, unit_price_cents: 1000))
      expect(item.subtotal_cents).to eq(3000)
    end
  end
end
