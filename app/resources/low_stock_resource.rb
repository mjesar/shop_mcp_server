class LowStockResource < ApplicationResource
  uri "shop://products/low-stock"
  resource_name "Low Stock Products"
  description "Products at or below a stock quantity of 5"
  mime_type "application/json"

  def content
    JSON.generate(
      Product.low_stock(5).map { |p| { id: p.id, title: p.title, sku: p.sku, stock_quantity: p.stock_quantity } }
    )
  end
end
