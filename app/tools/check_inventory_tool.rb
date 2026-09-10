class CheckInventoryTool < ApplicationTool
  description "Check current stock levels across the catalog, or flag every " \
              "product at or below a low-stock threshold."

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:threshold).filled(:integer).description(
      "Stock level at or below which a product is considered low (default 5)"
    )
  end

  def call(threshold: 5)
    low_stock = Product.low_stock(threshold).order(:stock_quantity)

    {
      threshold: threshold,
      low_stock_count: low_stock.count,
      low_stock_products: low_stock.map { |p| { id: p.id, title: p.title, sku: p.sku, stock_quantity: p.stock_quantity } }
    }
  end
end
