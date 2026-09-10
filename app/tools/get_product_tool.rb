class GetProductTool < ApplicationTool
  description "Get full details for a single product by its ID or SKU."

  arguments do
    optional(:id).maybe(:integer).description("Product ID")
    optional(:sku).maybe(:string).description("Product SKU, e.g. 'TOTE-001'")
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
