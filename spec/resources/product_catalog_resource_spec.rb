require "rails_helper"

RSpec.describe ProductCatalogResource do
  let!(:widget) { Product.create!(title: "Widget", sku: "WID-1", price_cents: 1999, stock_quantity: 3) }
  let!(:apple) { Product.create!(title: "Apple", sku: "APP-1", price_cents: 250, stock_quantity: 40) }

  it "returns the full catalog, ordered by title" do
    contents = described_class.contents
    payload = JSON.parse(contents.first.text)

    expect(contents.first.uri).to eq("shop://products/catalog")
    expect(contents.first.mime_type).to eq("application/json")
    expect(payload).to eq([
      { "id" => apple.id, "title" => "Apple", "sku" => "APP-1", "price" => 2.5, "stock_quantity" => 40 },
      { "id" => widget.id, "title" => "Widget", "sku" => "WID-1", "price" => 19.99, "stock_quantity" => 3 }
    ])
  end
end
