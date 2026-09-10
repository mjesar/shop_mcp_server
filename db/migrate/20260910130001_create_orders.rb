class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :customer_name,  null: false
      t.string :customer_email, null: false
      t.string :status,         null: false, default: "pending"

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, :customer_email
  end
end
