require "rails_helper"

RSpec.describe GetProductTool do
  let!(:product) do
    Product.create!(
      title: "Widget",
      sku: "WID-1",
      description: "A widget",
      price_cents: 1999,
      stock_quantity: 3
    )
  end

  it "finds a product by id" do
    response = described_class.call(id: product.id, server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(false)
    expect(result["id"]).to eq(product.id)
    expect(result["sku"]).to eq("WID-1")
    expect(result["price"]).to eq(19.99)
    expect(result["low_stock"]).to eq(true)
  end

  it "finds a product by sku" do
    response = described_class.call(sku: "WID-1", server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(false)
    expect(result["id"]).to eq(product.id)
    expect(result["title"]).to eq("Widget")
  end

  it "errors when neither id nor sku is given" do
    response = described_class.call(server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(true)
    expect(result["error"]).to eq("Provide either id or sku")
  end

  it "errors when the product cannot be found" do
    response = described_class.call(id: product.id + 1, server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(true)
    expect(result["error"]).to eq("Product not found")
  end
end
