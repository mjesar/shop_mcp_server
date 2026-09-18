namespace :embeddings do
  task backfill: :environment do
    products = Product.where(embedding: nil)
    texts = products.map { |product| "#{product.title} #{product.description}" }
    products.zip(VoyageClient.call(texts)).each do |product, embedding|
      product.update!(embedding: embedding)
    end
  end
end
