---
name: powerbi-mcp-skill
description: "How to connect to and query any Power BI / Fabric semantic model through the powerbi-modeling MCP server, which can reach many different workspaces and datasets - not just one. Use this whenever a Power BI question needs a live connection: listing workspaces, connecting to a dataset by name, or running/validating DAX. Domain-specific skills (e.g. drs-call-center-powerbi) provide the actual table/measure knowledge for one dataset; this skill covers the connection and query mechanics that apply to any of them."
---

# PowerBI MCP

The `powerbi-modeling` MCP server can reach many workspaces and datasets,
not just one — this skill covers the connection/query mechanics that apply
regardless of which one you're working with. A domain-specific skill (like
`drs-call-center-powerbi`) supplies the actual table/measure knowledge for
one dataset; this one gets you connected and lets you run DAX against it.

**This skill is for querying, not modeling.** The same MCP server can also
create/update/delete tables, columns, and measures (see
`semantic-model-authoring`) — don't use those operations here unless the
user explicitly asked to change the model, not just read from it.

## Step 1 — Check what's already connected

Before connecting, call `connection_operations` with `Operation:
ListConnections` — if the workspace/dataset you need is already connected,
reuse it by name instead of reconnecting. Omitting `connectionName` on later
calls uses "the last connection", convenient for a single dataset but a trap
the moment more than one is open — once you're working with multiple
workspaces, always pass `connectionName` explicitly.

## Step 2 — Connect

If not already connected, use `connection_operations`:
- **Power BI Service / Fabric workspace**: `Operation: ConnectFabric` with
  `workspaceName` and `semanticModelName` (exact-match names, not IDs — if
  the user only has an ID, ask them for the workspace/dataset name as shown
  in the Power BI portal instead).
- **Local Power BI Desktop / Analysis Services**: `Operation: Connect` with
  a connection string, or `ListLocalInstances` first to discover a running
  Desktop session.

Give the connection a memorable `connectionName` if you'll be switching
between workspaces in the same session — it's how you'll refer back to it.

## Step 3 — Query with DAX

Use `dax_query_operations`:
- `Validate` first for anything non-trivial — cheap (10s default timeout)
  and catches syntax errors before a real run.
- `Execute` to actually run it, passing the same `connectionName` you
  connected with. Set `maxRows` for exploratory queries.
- If results look stale after a model change, `ClearCache` before re-running.

## Step 4 — Check for domain knowledge first

Before writing DAX from scratch against an unfamiliar dataset, check whether
a domain-specific skill already documents it (table/column reference,
validated query templates, known pitfalls) — e.g. `drs-call-center-powerbi`
for the DRS Call Center dataset. Rediscovering a schema another skill
already recorded wastes calls.

## Working across multiple workspaces

Nothing here is tied to one dataset. If a question spans two workspaces
(e.g. comparing metrics), connect to both with distinct `connectionName`s
and pass the right one to each `dax_query_operations` call — don't rely on
"last connection" once more than one is open.
