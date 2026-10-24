<h1 align="center">
  <img src="assets/readme/hero.svg" alt="Shop MCP Server: a Ruby on Rails MCP server with semantic search (RAG) on pgvector" width="100%">
</h1>

<p align="center"><strong>Learn how to build an MCP server in Ruby on Rails that connects your app to AI assistants like Claude.</strong></p>

<p align="center">
  <a href="https://github.com/mjesar/shop_mcp_server/actions/workflows/ci.yml"><img src="https://github.com/mjesar/shop_mcp_server/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI status"></a>
  <img src="https://img.shields.io/badge/Ruby-4.0-CC342D?logo=ruby&logoColor=white" alt="Ruby 4.0">
  <img src="https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white" alt="Rails 8.1">
  <img src="https://img.shields.io/badge/PostgreSQL-pgvector-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL with pgvector">
  <img src="https://img.shields.io/badge/Protocol-MCP-2e7d4f" alt="Model Context Protocol">
  <img src="https://img.shields.io/badge/Embeddings-Voyage%20AI-c41e4a" alt="Voyage AI embeddings">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue" alt="MIT License"></a>
</p>

**Shop MCP Server is a Ruby on Rails MCP (Model Context Protocol) server that connects a Rails app to AI assistants such as Claude.** The example app is a small store: the assistant can read its products, orders and inventory, place orders, and search products by meaning. It is for Rails developers who want to see how an MCP server and a small RAG (retrieval-augmented generation) feature work in a real app.

It is built on the [official `mcp` Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk), PostgreSQL with [pgvector](https://github.com/pgvector/pgvector), and [Voyage AI](https://www.voyageai.com/) embeddings.

<p align="center">
  <img src="assets/readme/demo.gif" alt="Demo of Claude.ai using the Shop MCP Server as a custom connector: asked what the shop has for staying warm in winter, Claude calls the semantic search tool and lists the fleece jacket, merino wool scarf, cotton beanie and insulated mug; asked what is running low, it calls the inventory tool and flags the headphones with 3 left; asked for a gaming keyboard, semantic search returns nothing and Claude says the shop does not carry one; asked to order a scarf, Claude asks for approval before the create order tool runs and confirms order #3 for $35.00" width="800">
</p>

<details>
<summary>Text version of the demo</summary>

A real chat in Claude.ai, recorded on 2026-10-24, with this server running locally and connected to Claude as a custom connector through an ngrok tunnel. Waits are sped up.

1. **"What do you have for staying warm in winter?"** Claude calls `semantic_search_products_tool`. It lists the Fleece Zip-Up Jacket ($55), Merino Wool Scarf ($35), Cotton Knit Beanie ($15) and Insulated Travel Mug ($18).
2. **"Is anything running low on stock?"** Claude calls `check_inventory_tool` with the default threshold of 5. It flags the Wireless Noise-Cancelling Headphones (SKU ELC-003), with 3 left. The seed file gives them 15; I lowered it by hand before recording so the check had something to find.
3. **"Do you have a gaming keyboard?"** Semantic search returns nothing, and so does a title search. Claude says the shop does not carry one. It also notices on its own that "a similarity cutoff is filtering everything out".
4. **"Order one Merino Wool Scarf for Ali, ali@example.com"** Claude looks up the SKU with `list_products_tool`, then shows the order details and waits for approval before it runs `create_order_tool`. After approval it confirms order #3, pending, 1 × Merino Wool Scarf (SCF-001), $35.00.

Claude.ai also adds a "Language note" to each answer. That comes from a personal setting in my Claude account, not from this server.

</details>

## Why this exists

An AI assistant can only talk. It cannot check your database, place an order or know what is really in stock. Left alone, it guesses, and a guess that sounds right is worse than no answer.

MCP fixes that by giving the assistant a toolbox. Each tool is one clearly labeled capability, and the assistant reads the labels and decides on its own when to use one. Nobody hardcodes "when the user asks about stock, call this."

This is a learning project, and the most useful thing it taught me is that **the docs and the tutorials are not the source of truth, running code is.** Two examples:

- Claude reported an authentication problem with my first version. The real cause was the transport, and I rewrote the server on the official gem ([fix 1](#what-went-wrong-and-how-it-was-fixed)).
- The `mcp` gem's docs show prompt arguments with string keys. At runtime they arrive as symbols ([fix 2](#what-went-wrong-and-how-it-was-fixed)).

## See it work

<p align="center">
  <img src="assets/readme/architecture.svg" alt="Architecture diagram. An AI client (Claude, MCP Inspector or curl) sends JSON-RPC 2.0 messages with an Mcp-Session-Id header to the /mcp transport of the Rails app. The MCP server routes them to prompts (1), resources (2) or tools (7). Resources and tools read ActiveRecord models (Product, Order, OrderItem) in PostgreSQL with pgvector. The semantic search tool also calls VoyageClient, which sends an HTTPS request to the Voyage AI embeddings API." width="100%">
</p>

<details>
<summary>Text version of the diagram</summary>

An MCP client (Claude, MCP Inspector or curl) sends JSON-RPC 2.0 messages over HTTP, with an `Mcp-Session-Id` header, to one endpoint, `/mcp`. That endpoint is a `StreamableHTTPTransport` mounted in `config/routes.rb`. The transport hands each message to a single `MCP::Server`, which holds the registry of tools, resources and prompts and the session state.

Tools (`app/tools/*.rb`) query the database through plain ActiveRecord models (`Product`, `Order`, `OrderItem`), stored in PostgreSQL with the pgvector extension. Resources (`app/resources/*.rb`) read the same models. The semantic search tool also calls `VoyageClient` (`app/services/voyage_client.rb`), which sends an HTTPS POST to the Voyage AI embeddings API before it queries Postgres.

</details>

What the server exposes today, counted from [`config/routes.rb`](config/routes.rb) and the seed file:

| Piece | Count | Examples |
|---|---|---|
| Tools | 7 | `get_product_tool`, `create_order_tool`, `semantic_search_products_tool` |
| Resources | 2 | `shop://products/catalog`, `shop://products/low-stock` |
| Prompts | 1 | `inventory_check` |
| Seeded products | 10 | Merino Wool Scarf, Cotton Knit Beanie, Hiking Backpack 40L |

### Real runs

These ran on 2026-10-24 against the 10 seed products, with `mcp` 1.8.1 and Voyage `voyage-3.5-lite`. The tool calls went over the real MCP protocol with curl. The distances come from the same search run in the Rails console. Distance is cosine distance: 0 means the same meaning, and bigger means less related.

| Call | Result | What it shows |
|---|---|---|
| `list_products_tool`, search `"warm"` | 0 products | Keyword search only matches titles, and no title contains "warm" |
| `semantic_search_products_tool`, `"something warm for winter"` | Merino Wool Scarf (0.380), Fleece Zip-Up Jacket (0.380), Cotton Knit Beanie (0.458), Insulated Travel Mug (0.495) | Search by meaning finds what keyword search missed |
| `semantic_search_products_tool`, `"noise cancelling headphones for flights"` | Wireless Noise-Cancelling Headphones (0.244) first | A close match scores far lower than anything else |
| `semantic_search_products_tool`, `"a gift for someone who loves coffee"`, limit 3 | Insulated Travel Mug (0.348), Stainless Steel French Press (0.361), Merino Wool Scarf (0.438) | The scarf is a weak match that still passes the cutoff |
| `semantic_search_products_tool`, `"gaming keyboard"`, before the cutoff | Smart LED Desk Lamp (0.535), Portable Bluetooth Speaker (0.571), Cast Iron Camping Skillet (0.602) | The shop sells no keyboard, but search still returned its three "least bad" products |
| `semantic_search_products_tool`, `"gaming keyboard"`, after the cutoff | 0 products | Results farther than 0.5 are now dropped ([fix 3](#what-went-wrong-and-how-it-was-fixed)) |
| `create_order_tool`, 1 × `SCF-001` and 99 × `ELC-003` | `isError: true`, "Insufficient stock for ELC-003" | Still 0 orders and scarf stock still 40: the valid first line was rolled back too |

Before the cutoff, "something warm for winter" also returned the Portable Bluetooth Speaker in fifth place, at 0.537. The cutoff removed it.

These are hand runs, not a benchmark. The 0.5 cutoff comes from these numbers, on 10 products (see [Status](#status)).

## Quick start

You need Ruby (this project runs on 4.0.4), Bundler, and PostgreSQL 17 or newer with the pgvector extension (this project runs on PostgreSQL 18; on Ubuntu the package is `postgresql-18-pgvector`). `db/structure.sql` is dumped by PostgreSQL 18 and sets `transaction_timeout`, which PostgreSQL 16 does not know.

**Run the tests.** They need PostgreSQL but no API key, because no spec calls Voyage.

```bash
git clone https://github.com/mjesar/shop_mcp_server.git
cd shop_mcp_server
bundle install
bin/rails db:test:prepare
bundle exec rspec
```

This is the real output on my machine:

```
Finished in 0.7673 seconds (files took 1.63 seconds to load)
48 examples, 0 failures
```

**Run the server.** Semantic search needs a Voyage API key.

```bash
cp .env.example .env            # then fill in VOYAGE_API_KEY
bin/rails db:create db:migrate db:seed
bin/rails embeddings:backfill   # needed for semantic search only
bin/rails server
```

The seed and backfill steps print:

```
Seeded 10 products.
Embedded 10 products.
```

The MCP server is now live at `http://localhost:3000/mcp`. Check it by hand with the real protocol (Streamable HTTP is session-based, so there are three steps):

```bash
# 1. Initialize. The response carries an Mcp-Session-Id header.
curl -s -D - -o /dev/null http://localhost:3000/mcp \
  -H "Accept: application/json, text/event-stream" \
  --json '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"curl","version":"1.0"}}}'

# 2. Acknowledge. This is a notification (no id), so the server answers 202 with no body.
SESSION_ID=<paste the Mcp-Session-Id header value>
curl -s http://localhost:3000/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  --json '{"jsonrpc":"2.0","method":"notifications/initialized"}'

# 3. Call a tool.
curl -s http://localhost:3000/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  --json '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"list_products_tool","arguments":{"in_stock_only":true}}}'
```

Other ways to try it:

- **Straight from Ruby**, which is cheapest and skips the protocol: `bin/rails runner 'pp GetProductTool.call(sku: "SCF-001", server_context: {})'`. This does not prove argument validation works, so use curl for that.
- **MCP Inspector**: run `npx @modelcontextprotocol/inspector`, add a server with transport **Streamable HTTP** and URL `http://localhost:3000/mcp`.
- **Claude as a real client**: Claude connects from Anthropic's cloud, so `localhost` will not work. Expose the server first (for example `ngrok http 3000`), set `NGROK_HOST` in `.env`, then add a custom connector pointing at `https://<your-tunnel-url>/mcp`.

## How it works

A normal chat reply is `Question → Answer`. With MCP it becomes `Question → pick a tool → real data → Answer`. When someone asks an assistant *"what's running low on stock?"*:

1. **The client lists the tools.** It sends `tools/list` and the server returns every tool with its description. The registry is the `tools:` array in [`config/routes.rb`](config/routes.rb).
2. **The AI picks one.** It reads the descriptions and decides [`CheckInventoryTool`](app/tools/check_inventory_tool.rb) matches. The tool's own description says it flags "every product at or below a low-stock threshold."
3. **The client calls it.** It sends `tools/call` with arguments, for example `threshold: 10`. Without one, the threshold is 5.
4. **Rails runs real code.** The tool's `call` method is plain ActiveRecord against PostgreSQL, much like a controller action.
5. **The AI writes the answer** from the real numbers instead of guessing.

The protocol work (sessions, JSON-RPC framing, schemas) belongs to the gem. The app's own code is ordinary Ruby underneath it.

### Tools

| Tool | Type | What it does |
|---|---|---|
| `get_product_tool` | read-only | Full detail for one product, by ID or SKU |
| `list_products_tool` | read-only | Search or browse the catalog, optionally in-stock only |
| `check_inventory_tool` | read-only | Flags every product at or below a stock threshold (default 5) |
| `list_orders_tool` | read-only | Recent orders, optionally filtered by status |
| `get_order_tool` | read-only | Full order detail including line items |
| `create_order_tool` | **write** | Places an order and decrements stock, annotated `destructive_hint: true` |
| `semantic_search_products_tool` | read-only | Finds products by meaning using Voyage embeddings and pgvector cosine similarity |

Every tool declares [MCP annotations](https://ruby.sdk.modelcontextprotocol.io/server/tools/) (`read_only_hint`, `destructive_hint`, `idempotent_hint`, `open_world_hint`). A client uses them to decide what can run on its own and what needs the user's OK. In the demo, Claude shows the order details and waits for approval before `create_order_tool` runs. It also asked before `list_products_tool`, so how often Claude asks depends on the connector's permission settings too.

`create_order_tool` wraps its work in one `ActiveRecord::Base.transaction`. If any line item fails (unknown SKU, not enough stock), the whole order and every stock decrement is rolled back. [`spec/tools/create_order_tool_spec.rb`](spec/tools/create_order_tool_spec.rb) covers this.

### Resources and prompts

| Resource | URI | Content |
|---|---|---|
| Product Catalog | `shop://products/catalog` | Full catalog as JSON |
| Low Stock Products | `shop://products/low-stock` | Products at or below 5 units |

| Prompt | Argument | What it does |
|---|---|---|
| `inventory_check` | `threshold` (optional) | Hands the client a ready-made question: what is at or below N units, and what should I reorder? |

A resource is data a client reads directly, like opening a file. A prompt is a saved template that phrases a good question. The client's model then answers it, most likely by calling `check_inventory_tool`. Tools, resources and prompts are the three building blocks MCP defines, and this project uses all three.

### Semantic search (RAG)

Exact-match search fails when people describe what they want instead of naming it. `semantic_search_products_tool` finds products by meaning:

1. **Embed the products.** Each product's title and description go to Voyage AI (`voyage-3.5-lite`, 512 dimensions) through [`VoyageClient`](app/services/voyage_client.rb), a small `Net::HTTP` wrapper with no extra HTTP gem.
2. **Store the vectors.** The 512 numbers go into a `vector(512)` column on `products`, using pgvector and the [`neighbor`](https://github.com/ankane/neighbor) gem (`has_neighbors :embedding`).
3. **Embed the query the same way**, then ask Postgres for the closest stored vectors with `Product.nearest_neighbors(:embedding, query_vector, distance: "cosine")`. This step is plain geometry, with no AI involved.
4. **Drop the weak matches.** Nearest-neighbor search always returns the closest products, even when none is close, so the tool drops anything with a cosine distance above `MAX_DISTANCE = 0.5`. For "gaming keyboard" in a shop with no keyboards, that leaves an empty list instead of a desk lamp ([fix 3](#what-went-wrong-and-how-it-was-fixed)).
5. **Return the matches** to the calling client, which writes the answer. This app only does the "retrieval" half of RAG and never generates text itself.

Backfill embeddings for existing products with `bin/rails embeddings:backfill`. It only embeds products where `embedding` is `nil`, and it sends them all in **one batched API call**. Voyage's free tier can be as low as 3 requests per minute, so the task has to batch. Running it again when nothing is missing prints "All products already have embeddings." and makes no API call.

I use Voyage because [Anthropic's docs say Anthropic offers no embedding model of its own](https://platform.claude.com/docs/en/build-with-claude/embeddings) and recommend Voyage AI as the partner for Claude-based RAG.

### Data model

Money is stored as integer cents (`price_cents`, `unit_price_cents`) to avoid floating-point rounding. `unit_price_cents` is copied onto `OrderItem` at order time, so an order keeps showing what the customer actually paid even if the product price changes later.

<details>
<summary>Entity diagram (text version below)</summary>

```mermaid
erDiagram
    PRODUCT ||--o{ ORDER_ITEM : "ordered in"
    ORDER ||--o{ ORDER_ITEM : contains

    PRODUCT {
        integer id
        string title
        string sku
        text description
        integer price_cents
        integer stock_quantity
        vector embedding "512 dims, pgvector"
    }
    ORDER {
        integer id
        string customer_name
        string customer_email
        string status
    }
    ORDER_ITEM {
        integer id
        integer order_id
        integer product_id
        integer quantity
        integer unit_price_cents
    }
```

Text version: a `Product` (id, title, sku, description, price_cents, stock_quantity, a 512-dimension embedding) can appear in many `OrderItem` rows. An `Order` (id, customer_name, customer_email, status) has many `OrderItem` rows. An `OrderItem` (id, order_id, product_id, quantity, unit_price_cents) links one order to one product.

</details>

## Key terms

- **MCP (Model Context Protocol)**: an open protocol that lets an AI client discover and call tools, read resources and use prompts on a server, so the model can work with real data instead of guessing.
- **MCP server**: a program that exposes tools, resources and prompts over MCP. This repo is one, written in Ruby on Rails.
- **Tool**: one capability the AI can call, with a name, a description it reads, and an input schema. Example: `check_inventory_tool`.
- **Resource**: read-only data a client can open directly, like a file. Example: `shop://products/catalog`.
- **Prompt**: a saved, reusable question template a user can invoke.
- **Streamable HTTP**: the MCP transport that uses a single endpoint for both directions. Claude's custom connectors expect it.
- **JSON-RPC 2.0**: the message format MCP uses. A message with an `id` is a request that expects a reply. A message without one is a notification.
- **Embedding**: a list of numbers (here, 512) that represents the meaning of a piece of text, so similar meanings land close together.
- **pgvector**: a PostgreSQL extension that stores embeddings and finds the nearest ones.
- **RAG (retrieval-augmented generation)**: fetching relevant data first, then letting a model write its answer from it. This app does the retrieval half.

## Project structure

Most of the code is plain Ruby classes under `app/`. It is a Rails app mainly for autoloading, ActiveRecord, config and the test setup. You can ignore the generated `app/controllers`, `app/views`, `app/jobs` and `app/mailers` folders, plus `.kamal/` and the `Dockerfile`: they are Rails boilerplate.

```
shop_mcp_server/
├── app/
│   ├── tools/                       <-- the 7 MCP tools, one file each
│   ├── resources/                   <-- the 2 MCP resources
│   ├── prompts/
│   │   └── inventory_check_prompt.rb  <-- the one saved prompt
│   ├── models/                      <-- Product, Order, OrderItem
│   └── services/
│       └── voyage_client.rb         <-- Net::HTTP client for Voyage embeddings
├── config/
│   └── routes.rb                    <-- builds the MCP::Server and mounts it at /mcp
├── db/
│   ├── migrate/                     <-- tables, then the pgvector extension and embedding column
│   └── seeds.rb                     <-- the 10 sample products
├── lib/tasks/embeddings.rake        <-- bin/rails embeddings:backfill
├── spec/                            <-- RSpec: tools, resources, prompt, models
├── docs/mcp-concepts.md             <-- notes on what I verified while building
├── assets/readme/                   <-- the hero, the architecture diagram and the demo GIF
└── LICENSE                          <-- MIT
```

Inside `app/tools/`:

| File | What it does |
|---|---|
| `get_product_tool.rb` | One product by ID or SKU |
| `list_products_tool.rb` | Browse or search the catalog |
| `check_inventory_tool.rb` | Products at or below a stock threshold |
| `list_orders_tool.rb`, `get_order_tool.rb` | Read orders and their line items |
| `create_order_tool.rb` | The only write tool, in one transaction |
| `semantic_search_products_tool.rb` | Embeds the query, then runs the pgvector nearest-neighbor search |

## What went wrong, and how it was fixed

Each of these was found by running the server for real, not by the specs.

**1. Claude reported an authentication problem that was not one.** Connecting Claude to my first version failed, and Claude said authentication was the problem. I spent time on auth before checking the actual traffic. The cause was transport. `fast-mcp` only implements the legacy SSE transport, which uses a long-lived `GET` plus a separate `POST` endpoint. Claude's connector setup assumes Streamable HTTP, a single endpoint. So its `POST` landed on a `GET`-only route and got a 405, and the setup flow reported that as an auth error. `fast-mcp`'s GitHub issues #166 and #168 describe the same limitation. The fix was to move every tool and both resources to the official `mcp` gem, which implements Streamable HTTP natively. Notes on what changed are in [`docs/mcp-concepts.md`](docs/mcp-concepts.md).

That fix came with a trade-off. The gem offers two Rails patterns. **Mount** (what I use) builds one server at boot with full session lifecycle, but needs `config.enable_reloading = false`, so code changes need a restart. **Controller** builds a stateless server per request and keeps normal Rails reloading. I picked mount on purpose, to learn the fuller session architecture.

**2. Prompt arguments arrive with symbol keys, not the string keys the docs show.** The `mcp` gem's docs read prompt arguments as `args["threshold"]`. At runtime `InventoryCheckPrompt.template` receives `{threshold: "10"}`, so the string key was always `nil` and the threshold silently fell back to 5. A debug log line showed it, and I checked it again on `mcp` 1.8.1. [`spec/prompts/inventory_check_prompt_spec.rb`](spec/prompts/inventory_check_prompt_spec.rb) now fails if someone "fixes" the code back to string keys.

**3. Semantic search answered "gaming keyboard" with a desk lamp.** A nearest-neighbor query always returns the closest *k* products, even when none of them is close. The shop sells no keyboard, so it returned the three "least bad" products: a desk lamp, a speaker and a skillet. Claude would offer those as matches. The [real runs](#real-runs) show the gap: real matches score 0.24 to 0.38, and unrelated products 0.53 and up. [`SemanticSearchProductsTool`](app/tools/semantic_search_products_tool.rb) now drops anything farther than `MAX_DISTANCE = 0.5`, so "gaming keyboard" returns nothing and Claude says the shop does not carry one, as in the demo.

**4. The embeddings backfill crashed on its second run.** Once every product had an embedding, `bin/rails embeddings:backfill` sent Voyage an empty list, and Voyage answered 400 ("Input cannot be an empty string or empty list"). The task now prints "All products already have embeddings." and skips the call ([`lib/tasks/embeddings.rake`](lib/tasks/embeddings.rake)).

**5. CI was red from 2026-09-18 to 2026-10-24.** It broke with the move to PostgreSQL. `config/database.yml` hardcoded port 5434, where my local Postgres 16 ran, and the CI test job never started a Postgres at all. Then an OS upgrade removed Postgres 16, and the app could not boot locally either. The fix: drop the hardcoded port, so the app uses the default 5432, and give CI a `pgvector/pgvector:pg18` service. The same run turned up two smaller failures: `bin/brakeman` exits non-zero when brakeman is not the latest version, and bundler-audit flagged `crass` 1.0.7. Updating the gems fixed both.

### What keeps it reliable

- **Specs.** 48 RSpec examples cover all six non-search tools, both resources, the prompt and the models, calling each tool's `call` directly. Semantic search and the backfill task have no specs yet.
- **CI.** [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs Brakeman, bundler-audit, RuboCop and the specs against Postgres 18 with pgvector, on every pull request and every push to master.
- **Transactions.** `create_order_tool` rolls back everything if any line fails. A spec proves the order count and stock levels stay unchanged, and the [real runs](#real-runs) show the same thing over the protocol.
- **Annotations.** Read-only and write tools are declared, so a client can ask for approval before anything destructive. In the demo, Claude waits for approval before `create_order_tool` runs.
- **The real protocol, by hand.** I check behavior with curl, MCP Inspector and Claude itself, not only unit tests, because that is where every bug above showed up.

## Learn more

- [`docs/mcp-concepts.md`](docs/mcp-concepts.md): the running log of what I verified while building, including requests versus notifications, the three-step handshake, a tool's three names (`name`, `title`, `description`), and the symbol-versus-string prompt argument discrepancy
- [Official `mcp` Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk) and the [MCP specification](https://modelcontextprotocol.io/)
- [pgvector](https://github.com/pgvector/pgvector) and the [`neighbor`](https://github.com/ankane/neighbor) gem

### FAQ

#### How do I build an MCP server in Ruby on Rails?
Add the official `mcp` gem, define each tool as a class that inherits from `MCP::Tool` with an `input_schema` and a class-level `call` method, then build one `MCP::Server` in `config/routes.rb` and mount a `StreamableHTTPTransport` at `/mcp`. [`config/routes.rb`](config/routes.rb) and [`app/tools/`](app/tools/) show the whole thing.

#### Which Ruby gem should I use for MCP?
This project uses the official `mcp` gem from `modelcontextprotocol`. It is a different project from `fast-mcp` (by `yjacquin`) and from FastMCP, a Python framework, even though the names are close. I moved off `fast-mcp` because it only supports the legacy SSE transport.

#### Why does Claude say my MCP server has an authentication problem?
It may not be authentication. If your server only supports the legacy SSE transport, Claude's Streamable HTTP probe can get a 405 and be reported as an auth failure. That is what happened here, so check the transport first.

#### How do I connect a local MCP server to Claude?
Claude connects from Anthropic's cloud, so `localhost` does not work. Tunnel the server (for example with `ngrok http 3000`), set `NGROK_HOST`, and add a custom connector pointing at `https://<your-tunnel-url>/mcp`.

#### How do I add semantic search to a Rails app?
Embed your text with an embeddings API, store the vector in a pgvector column, and query it with the `neighbor` gem. The steps and code are in [Semantic search (RAG)](#semantic-search-rag) above.

#### Does this work with multiple Puma workers?
No. The gem keeps session state in a plain in-memory Ruby `Hash`, so it must run as a single process. See [Status](#status).

## Setup

The requirements are in [Quick start](#quick-start). The app uses PostgreSQL's default connection settings (port 5432). The usual `PGHOST`, `PGPORT`, `PGUSER` and `PGPASSWORD` variables override them, which is how CI connects.

- `VOYAGE_API_KEY`: needed for embeddings and semantic search. See [`.env.example`](.env.example). A key created through MongoDB Atlas's "Model API Key" flow authenticates against `ai.mongodb.com`, not `api.voyageai.com`, and `VoyageClient::ENDPOINT` is set for that Atlas-issued path.
- `NGROK_HOST`: optional, the full tunnel URL (for example `https://abc.ngrok-free.app`) when connecting Claude through a tunnel. The gem's DNS-rebinding protection (`allowed_hosts`, `allowed_origins`) matches **exact strings**, not regular expressions. `allowed_hosts` needs a bare hostname and `allowed_origins` needs scheme plus host, so [`config/routes.rb`](config/routes.rb) derives one from the other.

The project began on SQLite and moved to PostgreSQL because pgvector has no SQLite equivalent for this gem stack. If you do not need semantic search, the other six tools do not depend on pgvector.

## Tech stack

- Ruby 4.0.4 and Rails 8.1.4
- [`mcp`](https://github.com/modelcontextprotocol/ruby-sdk) 1.8.1, the official Ruby SDK
- PostgreSQL 18 with pgvector, via the [`neighbor`](https://github.com/ankane/neighbor) gem 1.2.0
- [Voyage AI](https://www.voyageai.com/) `voyage-3.5-lite`, 512-dimension embeddings
- RSpec (`rspec-rails` 8.0.4)

## Status

A working learning project, not production software, and not a full store backend.

Known limitations:

- **Sessions are in memory and single-process.** `StreamableHTTPTransport` stores sessions in a plain Hash with no pluggable store, so even multiple Puma workers break it, and a restart drops every session. The official Python and TypeScript SDKs share this design, and the newest MCP spec revision (2026-07-28) moves toward a stateless model to fix it.
- **No authentication.** Every caller is treated the same. Fine locally, not for a real deployment. While the server runs behind an ngrok tunnel, anyone with the URL can call every tool, including `create_order_tool`. `mcp` 1.8.0 added OAuth 2.1 resource server support to `StreamableHTTPTransport`, so that is the natural next step.
- **No live push.** `resources/subscribe` is not wired up, so a client re-reads a resource to see fresh data.
- **Type-only schema validation.** `input_schema` is plain JSON Schema, so tools guard against missing or bad input themselves.
- **Semantic search and the backfill task have no specs.** Both have only been checked by hand, in the [real runs](#real-runs) and the demo.
- **The 0.5 cutoff is tuned on 10 products.** A bigger or different catalog would need the distances checked again.
- **Embeddings are not kept in sync.** Editing a product does not re-embed it, because the backfill task only fills rows where `embedding` is `nil`. A production version would re-embed in an `after_commit` callback.
- **Voyage's default data-use terms are opt-out.** Text sent to the API may be used to improve their models unless you opt out in their dashboard. Check this before sending anything sensitive.

Not built here, in case you want to extend it: resource subscriptions, sampling, elicitation, OAuth-based authorization, and automatic re-embedding.

The code is released under the [MIT License](LICENSE).

## Related work

- [`product_geo_agent`](https://github.com/mjesar/product_geo_agent): a Rails CLI agent that scores how discoverable a Shopify product is to AI assistants (agents and tool calling).
- [`ai_shop_assistant`](https://github.com/mjesar/ai_shop_assistant): a shopping chat assistant that calls Shopify's live Catalog API over MCP (the client side of what this repo serves).
- [`support_engineer`](https://github.com/mjesar/support_engineer): a Rails 8 AI support agent that investigates orders and shipments, searches company policies and asks a human before it acts. A learning project in progress.
