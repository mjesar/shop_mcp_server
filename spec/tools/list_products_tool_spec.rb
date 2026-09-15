require "rails_helper"

RSpec.describe ListProductsTool do
  let!(:gadget) { Product.create!(title: "Gadget", sku: "GAD-1", price_cents: 500, stock_quantity: 0) }
  let!(:widget) { Product.create!(title: "Widget", sku: "WID-1", price_cents: 1000, stock_quantity: 5) }
  let!(:widget_pro) { Product.create!(title: "Widget Pro", sku: "WID-2", price_cents: 2000, stock_quantity: 2) }

  it "lists all products ordered by title by default" do
    response = described_class.call(server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(false)
    expect(result.map { |p| p["title"] }).to eq([ "Gadget", "Widget", "Widget Pro" ])
  end

  it "filters by a title search term" do
    response = described_class.call(search: "Widget", server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(result.map { |p| p["title"] }).to eq([ "Widget", "Widget Pro" ])
  end

  it "filters to only in-stock products" do
    response = described_class.call(in_stock_only: true, server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(result.map { |p| p["title"] }).to eq([ "Widget", "Widget Pro" ])
    expect(result.map { |p| p["sku"] }).not_to include("GAD-1")
  end
end
