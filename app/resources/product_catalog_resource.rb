class ProductCatalogResource < ApplicationResource
  uri "shop://products/catalog"
  resource_name "Product Catalog"
  description "The full current product catalog, including stock levels"
  mime_type "application/json"

  def content
    JSON.generate(
      Product.order(:title).map do |p|
        { id: p.id, title: p.title, sku: p.sku, price: p.price, stock_quantity: p.stock_quantity }
      end
    )
  end
end
