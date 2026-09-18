class AddEmbeddingToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :embedding, :vector, limit: 512
  end
end
