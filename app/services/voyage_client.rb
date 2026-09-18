# app/services/voyage_client.rb
require "net/http"
require "json"
class VoyageClient
  class Error < StandardError; end

  ENDPOINT = "https://ai.mongodb.com/v1/embeddings"
  MODEL = "voyage-3.5-lite"
  OUTPUT_DIMENSION = 512

  def self.call(texts)
    new.embed(texts)
  end

  def embed(texts)
    uri = URI(ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{ENV["VOYAGE_API_KEY"]}"
    request.body = {
      model: MODEL,
      output_dimension: OUTPUT_DIMENSION,
      input: texts
    }.to_json

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)["data"]
      data.sort_by { |item| item["index"] }.map { |item| item["embedding"] }
    else
      raise Error, "Voyage API error: #{response.code} #{response.body}"
    end
  end
end
