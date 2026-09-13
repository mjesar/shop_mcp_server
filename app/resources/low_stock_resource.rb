class LowStockResource < MCP::Resource
  uri "shop://products/low-stock"
  resource_name "Low Stock Products"
  title "Low Stock Resource"
  description "Products at or below a stock quantity of 5"
  mime_type "application/json"

  class << self
    def contents
      products = Product.low_stock(5).map { |p| { id: p.id, title: p.title, sku: p.sku, stock_quantity: p.stock_quantity } }
      [ MCP::Resource::TextContents.new(uri: uri, mime_type: mime_type, text: JSON.generate(products)) ]
    end
  end
end
