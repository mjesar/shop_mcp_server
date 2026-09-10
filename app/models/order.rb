class Order < ApplicationRecord
  STATUSES = %w[pending paid fulfilled cancelled].freeze

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :customer_name, presence: true
  validates :customer_email, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_status, ->(status) { where(status: status) }

  def total_cents
    order_items.sum("quantity * unit_price_cents")
  end

  def total
    total_cents / 100.0
  end
end
