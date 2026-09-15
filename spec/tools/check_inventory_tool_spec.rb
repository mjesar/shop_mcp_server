require "rails_helper"

RSpec.describe CheckInventoryTool do
  let!(:out_of_stock) { Product.create!(title: "Out of Stock", sku: "SKU-0", price_cents: 100, stock_quantity: 0) }
  let!(:low) { Product.create!(title: "Low", sku: "SKU-3", price_cents: 100, stock_quantity: 3) }
  let!(:at_threshold) { Product.create!(title: "At Threshold", sku: "SKU-5", price_cents: 100, stock_quantity: 5) }
  let!(:well_stocked) { Product.create!(title: "Well Stocked", sku: "SKU-10", price_cents: 100, stock_quantity: 10) }

  it "flags products at or below the default threshold of 5" do
    response = described_class.call(server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(false)
    expect(result["threshold"]).to eq(5)
    expect(result["low_stock_count"]).to eq(3)
    expect(result["low_stock_products"].map { |p| p["sku"] }).to eq(%w[SKU-0 SKU-3 SKU-5])
  end

  it "flags products at or below a custom threshold" do
    response = described_class.call(threshold: 2, server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(result["threshold"]).to eq(2)
    expect(result["low_stock_count"]).to eq(1)
    expect(result["low_stock_products"].map { |p| p["sku"] }).to eq(%w[SKU-0])
  end
end
