# MCP concepts notes (for README)

Running notes captured while migrating from `fast-mcp` to the official
`mcp` Ruby SDK. Fold these into the README's "How it works" / concepts
section once the migration is done.

## JSON-RPC notifications vs requests
- The entire distinction is one field: **does the message have an `id`?**
- Has `id` → a **request**. Sender expects a reply matched back to that `id`.
- No `id` → a **notification**. Fire-and-forget, no reply expected — the
  server just answers `202 Accepted` (or nothing at all) rather than a
  JSON-RPC response body.
- Example without id: `{"jsonrpc":"2.0","method":"notifications/initialized"}`
- Example with id: `{"jsonrpc":"2.0","id":1,"method":"initialize",...}`
- This one mechanism covers *every* "notification" in MCP: handshake
  notifications (client → server, once, at connection start) and
  resource-update notifications (server → client, whenever data changes,
  for clients that used `resources/subscribe` — not implemented in this
  project).

## The MCP handshake (Streamable HTTP, session-based)
1. Client sends `initialize` (has `id`) → server responds with its
   capabilities and issues a session, returned via the `Mcp-Session-Id`
   response header.
2. Client sends `notifications/initialized` (no `id`) → server replies
   `202 Accepted`. This says "I've seen your capabilities, ready to talk
   normally."
3. Connection is now live: `tools/list`, `tools/call`, `resources/list`,
   etc. all work, each request carrying the `Mcp-Session-Id` header.

## Streamable HTTP vs legacy SSE (why we migrated)
- **Legacy SSE** (`fast-mcp`): two separate endpoints — a long-lived `GET`
  the server pushes down (one-way), and a separate `POST` endpoint for
  client → server messages. Two connections, awkward two-line phone-call
  analogy.
- **Streamable HTTP** (official `mcp` gem): one endpoint. A `POST` can get
  back either a plain JSON response *or* an SSE-framed response (prefixed
  `data: `), depending on what's needed — same endpoint handles both
  directions.
- This is why Claude's connector setup (which probes assuming Streamable
  HTTP) 405'd against `fast-mcp`'s SSE-only `/mcp/sse` route.

## Rails mounting patterns for this gem
- **Mount** (what we used): one `MCP::Server` + transport built once at
  boot, in `config/routes.rb` (not an initializer — Zeitwerk autoloading
  isn't ready yet when initializers run, but routes load late enough that
  tool classes are available). Supports full session lifecycle, in-memory
  state, live push notifications. Trade-off: requires
  `config.enable_reloading = false` — every code change needs a full
  server restart, not just new files.
- **Controller** (not used here): a plain `ActionController::API` action
  builds a *fresh* `MCP::Server` per request with `stateless: true`, calls
  `transport.handle_request(request)`, and renders the returned
  `[status, headers, body]`. Normal Rails dev workflow, no reloading
  trade-off. No cross-request state or push notifications. Chosen against,
  specifically to learn the fuller session-lifecycle architecture instead.
- Both patterns are documented in the gem's top-level README under
  "Rails (mount)" and "Rails (controller)".

## A tool's three names: `name`, `title`, `description`
- **`name`** — the machine identifier, e.g. `get_product_tool`. Derived
  automatically from the class name. This is what appears in JSON-RPC
  calls (`"method":"tools/call","params":{"name":"get_product_tool"}`).
  Not meant for a human to read.
- **`title`** — a short, human-friendly display label, e.g.
  `"Get Product"`. What a client's UI shows a *person* (e.g. Claude's
  tool-permissions screen showing "Get Product" instead of the raw
  snake_case name).
- **`description`** — the longer explanation the *LLM* reads to decide
  when and how to use the tool.
- `fast-mcp` only had two of these (derived `name` + `description`);
  `title` is new in this gem, part of a newer MCP spec revision adding
  better human-facing metadata separate from the machine name.

## Tool API differences: fast-mcp vs official mcp gem
| | fast-mcp | official mcp gem |
|---|---|---|
| Base class | `ApplicationTool` (`< ActionTool::Base`) | `MCP::Tool` directly |
| Arguments | `arguments do ... end` (dry-schema DSL: `.filled`, `.maybe`, validated automatically) | `input_schema(properties: {...}, required: [...])` — raw JSON Schema, type-only, no built-in presence/shape validation |
| Call signature | instance method: `def call(search: nil, ...)` | class method: `class << self; def call(...); end; end`, must accept `server_context:` keyword even if unused |
| Return value | plain Ruby hash/array — gem serializes it | `MCP::Tool::Response.new([{type: "text", text: "..."}])` — we JSON-generate our own data into the `text` field ourselves |
| Registration | auto-discovered via `ApplicationTool.descendants` | explicit: every tool listed by hand in the `tools: [...]` array passed to `MCP::Server.new` |
| Annotations | `annotations(read_only_hint:, destructive_hint:, idempotent_hint:, open_world_hint:)` | identical keys/shape — unchanged |

Net effect: less automatic protection (no schema-validation rejection
before `call` runs — bad input now reaches our code and we must guard it
ourselves, same as we always did for our own business-logic checks), but
a clearer, more explicit picture of exactly what's registered and how a
request becomes a response.
