# synology-mcp

Optional add-on plugin that connects Claude Code to a Synology NAS through
[`atom2ueki/mcp-server-synology`](https://github.com/atom2ueki/mcp-server-synology) — file
operations, download management, system monitoring, and container orchestration on your
NAS.

## Why the endpoint isn't baked in here

Unlike `cloudflare-mcp`, there's no official Claude Code plugin/marketplace for this
project to depend on, and the server itself talks to one specific NAS with real
credentials — there's nothing generic to redistribute. So this plugin declares the
`.mcp.json` shape (an `sse`-type server, matching `mcp-proxy`'s default transport — see
below) but leaves the actual endpoint as a
[`userConfig`](https://code.claude.com/docs/en/plugins-reference#user-configuration)
value, `synology_mcp_url`, prompted at enable time and marked `sensitive`. That value is
stored in your OS keychain (or `~/.claude/.credentials.json` where no keychain is
available) — never written into this repo or any commit. This repo's own ground rules
(see [`CONTRIBUTING.md`](../../CONTRIBUTING.md)) rule out committing a private
NAS/reverse-proxy hostname directly, since this is a public marketplace.

## Prerequisite — run your own instance

This plugin is a client, not a server. You need your own running instance of
`mcp-server-synology` reachable remotely:

1. Deploy [`atom2ueki/mcp-server-synology`](https://github.com/atom2ueki/mcp-server-synology)
   (Docker Compose is the fastest path) with your NAS's `SYNOLOGY_URL` /
   `SYNOLOGY_USERNAME` / `SYNOLOGY_PASSWORD` — see that repo's README.
2. Its default transport is stdio; expose it remotely with
   [`mcp-proxy`](https://github.com/sparfenyuk/mcp-proxy) (`mcp-proxy --port=8080 -- <stdio
   command>`), fronted by your own TLS-terminating reverse proxy. **`mcp-proxy` defaults
   to SSE transport**, served at `/sse` — that's why this plugin declares its server as
   `"type": "sse"` rather than `"http"` (Streamable HTTP); the two are distinct
   protocols in Claude Code's MCP client and using the wrong one breaks the handshake.
3. The URL you supply below must be the **full SSE endpoint**, e.g.
   `https://your-host.example.com/sse` — not just the bare host. Keep it out of any file
   in this repo; supply it interactively (below) instead.

## Enable it

```bash
claude plugin marketplace add nilpost/claude-code-studio   # if not already added
claude plugin install synology-mcp@claude-code-studio --scope user
# prompts for "Synology MCP server SSE URL" — paste your own instance's /sse endpoint
```

Non-interactive (cloud sessions, CI):

```bash
claude plugin install synology-mcp@claude-code-studio --scope user \
  --config synology_mcp_url=https://your-own-synology-mcp-instance.example.com/sse
```

## Secure your endpoint

Claude Code sends requests straight to the URL you configure — this plugin doesn't add
authentication of its own. Put real access control in front of it (network allowlist,
mTLS, a reverse-proxy auth layer, etc.), since it's a control plane for your NAS.
