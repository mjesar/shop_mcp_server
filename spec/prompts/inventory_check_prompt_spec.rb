require "rails_helper"

RSpec.describe InventoryCheckPrompt do
  it "uses the given threshold when args is keyed by symbol, as the mcp gem actually passes it" do
    result = described_class.template({ threshold: 10 }, server_context: {})
    text = result.messages.first.content.text

    expect(text).to eq(
      "What products are at or below 10 units in stock right now, and which ones should I reorder first?"
    )
  end

  it "defaults to a threshold of 5 when no threshold arg is given" do
    result = described_class.template({}, server_context: {})
    text = result.messages.first.content.text

    expect(text).to include("at or below 5 units")
  end

  it "does not pick up a string-keyed threshold" do
    # Regression guard: the mcp gem's own docs show prompt args with string keys,
    # but at runtime it actually calls #template with a symbol-keyed hash. If this
    # code were "corrected" to match the docs (args["threshold"]) it would silently
    # stop reading the real argument and always fall back to the default.
    result = described_class.template({ "threshold" => 10 }, server_context: {})
    text = result.messages.first.content.text

    expect(text).to include("at or below 5 units")
  end
end
