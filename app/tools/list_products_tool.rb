class ListProductsTool < ApplicationTool
  description "List products in the store catalog, optionally filtered by " \
              "a title search term and/or stock availability."

  arguments do
    optional(:search).maybe(:string).description("Case-insensitive substring to match against product titles")
    optional(:in_stock_only).maybe(:bool).description("If true, only return products with stock_quantity > 0")
    optional(:limit).filled(:integer).description("Max number of products to return (default 20)")
  end

  def call(search: nil, in_stock_only: false, limit: 20)
    scope = Product.all
    scope = scope.search_by_title(search) if search.present?
    scope = scope.in_stock if in_stock_only
    scope = scope.order(:title).limit(limit)

    scope.map do |product|
      {
        id: product.id,
        title: product.title,
        sku: product.sku,
        price: product.price,
        stock_quantity: product.stock_quantity
      }
    end
  end
end
