require "rails_helper"

RSpec.describe LowStockResource do
  let!(:low) { Product.create!(title: "Low", sku: "LOW-1", price_cents: 500, stock_quantity: 4) }
  let!(:well_stocked) { Product.create!(title: "Well Stocked", sku: "OK-1", price_cents: 500, stock_quantity: 20) }

  it "returns only products at or below a stock quantity of 5" do
    contents = described_class.contents
    payload = JSON.parse(contents.first.text)

    expect(contents.first.uri).to eq("shop://products/low-stock")
    expect(contents.first.mime_type).to eq("application/json")
    expect(payload).to eq([
      { "id" => low.id, "title" => "Low", "sku" => "LOW-1", "stock_quantity" => 4 }
    ])
  end
end
