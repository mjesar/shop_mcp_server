require "rails_helper"

RSpec.describe ListOrdersTool do
  let!(:pending_order) do
    Order.create!(customer_name: "A", customer_email: "a@example.com", status: "pending", created_at: 3.days.ago)
  end
  let!(:paid_order_older) do
    Order.create!(customer_name: "B", customer_email: "b@example.com", status: "paid", created_at: 2.days.ago)
  end
  let!(:paid_order_newer) do
    Order.create!(customer_name: "C", customer_email: "c@example.com", status: "paid", created_at: 1.day.ago)
  end
  let!(:fulfilled_order) do
    Order.create!(customer_name: "D", customer_email: "d@example.com", status: "fulfilled", created_at: Time.current)
  end

  it "filters orders by status, most recent first" do
    response = described_class.call(status: "paid", server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(response.error?).to eq(false)
    expect(result.map { |o| o["id"] }).to eq([ paid_order_newer.id, paid_order_older.id ])
    expect(result.map { |o| o["status"] }).to all(eq("paid"))
  end

  it "limits the number of orders returned to the most recent ones" do
    response = described_class.call(limit: 2, server_context: {})
    result = JSON.parse(response.content.first[:text])

    expect(result.size).to eq(2)
    expect(result.map { |o| o["id"] }).to eq([ fulfilled_order.id, paid_order_newer.id ])
  end
end
