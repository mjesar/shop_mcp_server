require "rails_helper"

RSpec.describe Product do
  let(:valid_attributes) do
    { title: "Widget", sku: "WID-1", price_cents: 1999, stock_quantity: 5 }
  end

  it "is valid with valid attributes" do
    expect(Product.new(valid_attributes)).to be_valid
  end

  it "requires a title" do
    product = Product.new(valid_attributes.merge(title: nil))
    expect(product).not_to be_valid
    expect(product.errors[:title]).to be_present
  end

  it "requires a sku" do
    product = Product.new(valid_attributes.merge(sku: nil))
    expect(product).not_to be_valid
    expect(product.errors[:sku]).to be_present
  end

  it "requires the sku to be unique" do
    Product.create!(valid_attributes)
    duplicate = Product.new(valid_attributes.merge(title: "Other Widget"))

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:sku]).to include("has already been taken")
  end

  it "rejects a negative price" do
    product = Product.new(valid_attributes.merge(price_cents: -1))
    expect(product).not_to be_valid
    expect(product.errors[:price_cents]).to be_present
  end

  it "rejects a negative stock quantity" do
    product = Product.new(valid_attributes.merge(stock_quantity: -1))
    expect(product).not_to be_valid
    expect(product.errors[:stock_quantity]).to be_present
  end

  describe "#price" do
    it "converts cents to dollars" do
      product = Product.new(valid_attributes.merge(price_cents: 1999))
      expect(product.price).to eq(19.99)
    end
  end

  describe "#low_stock?" do
    it "is true at or below the threshold" do
      product = Product.new(valid_attributes.merge(stock_quantity: 5))
      expect(product.low_stock?).to eq(true)
    end

    it "is false above the threshold" do
      product = Product.new(valid_attributes.merge(stock_quantity: 6))
      expect(product.low_stock?).to eq(false)
    end

    it "accepts a custom threshold" do
      product = Product.new(valid_attributes.merge(stock_quantity: 6))
      expect(product.low_stock?(10)).to eq(true)
    end
  end

  describe "deletion" do
    it "is blocked when the product has order items" do
      product = Product.create!(valid_attributes)
      order = Order.create!(customer_name: "Alice", customer_email: "alice@example.com", status: "pending")
      order.order_items.create!(product: product, quantity: 1, unit_price_cents: product.price_cents)

      expect(product.destroy).to eq(false)
      expect(product.errors[:base]).to be_present
      expect(Product.exists?(product.id)).to eq(true)
    end
  end
end
