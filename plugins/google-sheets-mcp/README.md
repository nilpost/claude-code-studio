# google-sheets-mcp

Adds Google's own official remote MCP server for Google Sheets —
[`sheetsmcp.googleapis.com`](https://developers.google.com/workspace/sheets/api/guides/configure-mcp-server),
documented at
[Configure the Google Workspace MCP servers](https://developers.google.com/workspace/guides/configure-mcp-servers).
Read/write cell values, formulas, sheet/grid structure, and metadata, scoped to
whatever Google account authorizes it.

## Why this is a direct declaration, not a userConfig prompt

Unlike `synology-mcp`, there's nothing private here to protect: this is a single,
publicly-documented, Google-operated endpoint, not a per-user self-hosted instance.
Auth is per-user OAuth against `accounts.google.com`, discovered automatically via the
endpoint's `.well-known/oauth-protected-resource` metadata — the same mechanism
`cloudflare-mcp` relies on. Claude Code drives the browser OAuth flow on first tool use;
no client ID/secret or token is stored in this repo.

Verified directly against the endpoint (2026-07-31, before adding it here): a raw MCP
`initialize` call returns a standard handshake response, and its OAuth Protected
Resource metadata lists `accounts.google.com` as the authorization server with
`spreadsheets` and `drive` scopes (`spreadsheets`, `spreadsheets.readonly`, `drive`,
`drive.readonly`).

## Enable it

```bash
claude plugin marketplace add nilpost/claude-code-studio   # if not already added
claude plugin install google-sheets-mcp@claude-code-studio --scope user
```

First tool call triggers the Google OAuth consent screen for the scopes above — accept
only the scope level (readonly vs. read/write) you actually need.

## A note on the original ask

The plugin was originally requested as `@anthropic-ai/mcp-server-google-sheets`, an npm
package that doesn't exist (404 on the npm registry). This official Google-hosted
endpoint does the same job without needing any package at all — nothing to install,
nothing to keep updated.
