class InventoryCheckPrompt < MCP::Prompt
  prompt_name "inventory_check"
  title "Daily Inventory Check"
  description "Ask what's low on stock right now, so you know what to reorder."
  arguments [
    MCP::Prompt::Argument.new(
      name: "threshold",
      title: "Low stock threshold",
      description: "Stock level at or below which a product counts as low (default 5)",
      required: false
    )
  ]

  class << self
    def template(args, server_context:)
      Rails.logger.info "PROMPT ARGS: #{args.inspect}"
      threshold = args[:threshold] || "5"

      MCP::Prompt::Result.new(
        description: "Check current low-stock products",
        messages: [
          MCP::Prompt::Message.new(
            role: "user",
            content: MCP::Content::Text.new(
              "What products are at or below #{threshold} units in stock right now, and which ones should I reorder first?"
            )
          )
        ]
      )
    end
  end
end
