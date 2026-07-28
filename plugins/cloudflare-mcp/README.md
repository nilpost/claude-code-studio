# cloudflare-mcp

Bundles Cloudflare's remote MCP servers as a plugin so they load in every local project
and every cloud session that installs it — same "one install, everywhere" mechanism as
`studio-core`.

Enabled by default in `.mcp.json`:

| Server | URL |
| --- | --- |
| Documentation | `https://docs.mcp.cloudflare.com/mcp` |
| Workers Bindings (D1, KV, R2, Hyperdrive, Workers) | `https://bindings.mcp.cloudflare.com/mcp` |

## Adding more Cloudflare servers

Cloudflare publishes several other remote MCP servers. Add any of these to
`.mcp.json` the same way (`"type": "http"`, `"url": "..."`):

| Server | URL |
| --- | --- |
| Workers Builds | `https://builds.mcp.cloudflare.com/mcp` |
| Observability | `https://observability.mcp.cloudflare.com/mcp` |
| Container | `https://containers.mcp.cloudflare.com/mcp` |
| Browser Rendering | `https://browser.mcp.cloudflare.com/mcp` |
| Logpush | `https://logs.mcp.cloudflare.com/mcp` |
| AI Gateway | `https://ai-gateway.mcp.cloudflare.com/mcp` |
| Audit Logs | `https://auditlogs.mcp.cloudflare.com/mcp` |
| DNS Analytics | `https://dns-analytics.mcp.cloudflare.com/mcp` |
| Digital Experience Monitoring | `https://dex.mcp.cloudflare.com/mcp` |
| Cloudflare One CASB | `https://casb.mcp.cloudflare.com/mcp` |
| GraphQL | `https://graphql.mcp.cloudflare.com/mcp` |
| Cloudflare Blog | `https://blog.mcp.cloudflare.com/mcp` |

Source: [cloudflare/mcp-server-cloudflare](https://github.com/cloudflare/mcp-server-cloudflare).

## Auth

Each server OAuths independently on first tool use — no tokens to store in this repo.
