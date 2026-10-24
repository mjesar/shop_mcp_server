class SemanticSearchProductsTool < MCP::Tool
  title "Semantic Search Products Tool"
  description "Semantic search of products"

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      query: { type: "string", description: "Natural language description of what to search for, e.g. 'something warm for winter'" },
      limit: { type: "integer", description: "Limit how many product need to be found" }
    },
    required: [ "query" ]
  )

  # Cosine distance above which a product is too unrelated to return. Real matches in the
  # seed catalog score 0.24 to 0.38, unrelated ones 0.53 and up ("gaming keyboard" -> desk lamp).
  MAX_DISTANCE = 0.5

  class << self
    def call(query:, limit: 5, server_context:)
      begin
        text = VoyageClient.call([ query ]).first
        result = Product.nearest_neighbors(:embedding, text, distance: "cosine").first(limit)
        result = result.select { |product| product.neighbor_distance <= MAX_DISTANCE }
        response = result.map do |product|
          { title: product.title, description: product.description, price: product.price }
        end

        MCP::Tool::Response.new([ { type: "text", text: JSON.generate(response) } ])
      rescue VoyageClient::Error => e
        MCP::Tool::Response.new([ { type: "text", text: JSON.generate({ error: e.message }) } ], error: true)
      end
    end
  end
end
