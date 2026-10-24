namespace :embeddings do
  task backfill: :environment do
    products = Product.where(embedding: nil).to_a

    # Voyage rejects an empty input list with a 400, so a second run must not call it.
    if products.empty?
      puts "All products already have embeddings."
      next
    end

    texts = products.map { |product| "#{product.title} #{product.description}" }
    products.zip(VoyageClient.call(texts)).each do |product, embedding|
      product.update!(embedding: embedding)
    end
    puts "Embedded #{products.size} products."
  end
end
