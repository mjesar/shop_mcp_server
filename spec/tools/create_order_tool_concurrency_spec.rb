require "rails_helper"

RSpec.describe CreateOrderTool, "when another transaction is changing the same stock" do
  # The order has to run on its own database connection, and it can only see
  # committed data there, so this file cannot use the usual wrapping transaction.
  self.use_transactional_tests = false

  let!(:product) { Product.create!(title: "Last Widget", sku: "RACE-1", price_cents: 1000, stock_quantity: 1) }

  after do
    OrderItem.where(product: product).delete_all
    Order.where(customer_email: "race@example.com").delete_all
    product.delete
  end

  def wait_until_another_connection_is_blocked
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5

    until blocked_connections.positive?
      raise "the order never waited on the row lock" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.01
    end
  end

  def blocked_connections
    # Inside a transaction Postgres keeps returning the first pg_stat_activity
    # snapshot it took, so clear it to get a fresh answer on every poll.
    ActiveRecord::Base.connection.execute("SELECT pg_stat_clear_snapshot()")
    ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT count(*) FROM pg_stat_activity
      WHERE datname = current_database() AND wait_event_type = 'Lock'
    SQL
  end

  it "reads the stock only after the other transaction commits, so it cannot oversell" do
    order_thread = nil

    begin
      Product.transaction do
        product.lock!

        order_thread = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            described_class.call(
              customer_name: "Racer",
              customer_email: "race@example.com",
              line_items: [ { "sku" => "RACE-1", "quantity" => 1 } ],
              server_context: {}
            )
          end
        end

        wait_until_another_connection_is_blocked
        product.update!(stock_quantity: 0)
      end
    ensure
      order_thread&.join
    end

    response = order_thread.value
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(true)
    expect(result["error"]).to eq("Insufficient stock for RACE-1")
    expect(product.reload.stock_quantity).to eq(0)
    expect(Order.where(customer_email: "race@example.com")).to be_empty
  end
end
