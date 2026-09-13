class ProductCatalogResource < MCP::Resource
  uri "shop://products/catalog"
  resource_name "Product Catalog"
  title "Product Catalog"
  description "The full current product catalog, including stock levels"
  mime_type "application/json"

  class << self
    def contents
      products = Product.order(:title).map do |p|
        { id: p.id, title: p.title, sku: p.sku, price: p.price, stock_quantity: p.stock_quantity }
      end

      [ MCP::Resource::TextContents.new(uri: uri, mime_type: mime_type, text: JSON.generate(products)) ]
    end
  end
end
