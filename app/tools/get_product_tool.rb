class GetProductTool < ApplicationTool
  description "Get full details for a single product by its ID or SKU."

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:id).filled(:integer).description("Product ID")
    optional(:sku).filled(:string).description("Product SKU, e.g. 'TOTE-001'")
  end

  def call(id: nil, sku: nil)
    product = if id
                Product.find_by(id: id)
    elsif sku
                Product.find_by(sku: sku)
    end

    return { error: "Provide either id or sku" } if id.nil? && sku.nil?
    return { error: "Product not found" } unless product

    {
      id: product.id,
      title: product.title,
      sku: product.sku,
      description: product.description,
      price: product.price,
      stock_quantity: product.stock_quantity,
      low_stock: product.low_stock?
    }
  end
end
