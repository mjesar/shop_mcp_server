class Product < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, through: :order_items

  validates :title, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :low_stock, ->(threshold = 5) { where(stock_quantity: 0..threshold) }
  scope :search_by_title, ->(term) { where("title LIKE ?", "%#{sanitize_sql_like(term)}%") }

  def price
    price_cents / 100.0
  end

  def low_stock?(threshold = 5)
    stock_quantity <= threshold
  end
end
