class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string  :title,          null: false
      t.string  :sku,            null: false
      t.text    :description
      t.integer :price_cents,    null: false, default: 0
      t.integer :stock_quantity, null: false, default: 0

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :title
  end
end
