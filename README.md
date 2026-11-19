# Septeo Legal MCP — can Prestance be the MCP client?

Spike of 2026-11-19. Question: can Prestance connect to a law firm's Septeo
Legal / Secib data through Septeo's MCP server (`https://ssa-mcp.septeo.fr/mcp`)
as its own client, not through Claude?

**Answer: not today.** Septeo's auth server only accepts client identifiers it
already knows. Prestance's identifier is rejected before Septeo even reads it.

## How the server works

- `ssa-mcp.septeo.fr/mcp` answers `401` and names its auth server,
  `https://passport.secib.fr`, with read-only scopes: `agenda.read`,
  `cabinet.read`, `dossier.read`, `document.read`, `personne.read`, plus
  `openid profile offline_access`.
- `passport.secib.fr` has no dynamic client registration (no
  `registration_endpoint`). It advertises `client_id_metadata_document_supported:
true`: a client identifies itself with an HTTPS URL that hosts its metadata
  (name, redirect URIs). Public clients (`token_endpoint_auth_method: none`)
  with PKCE are allowed.
- Septeo enables the connector per firm, on the firm's request
  (Tech-expert@septeo.com). A user from a firm without it cannot log in.
  Sessions expire after 24 h without use and after 30 days at most
  (septeo.legal/mcp/confidentialite).

## What was tested

`./probe.sh` starts a login for each client and reports whether Septeo's login
page opens. It needs no account and stops before the login.

| Client                                                 | Result   |
| ------------------------------------------------------ | -------- |
| Claude (`claude.ai/oauth/mcp-oauth-client-metadata`)   | LOGIN    |
| Claude Code (`claude.ai/oauth/claude-code-client-...`) | LOGIN    |
| VS Code (`vscode.dev/oauth/client-metadata.json`)      | REJECTED |
| Prestance (`docs/oauth/client-metadata.json`)          | REJECTED |

Prestance's document has the same shape as Claude Code's and is served as
`application/json` (GitHub Pages: `jiliac.github.io/septeo-spike`). It was
also tried as `text/plain` (a gist) and with a port-specific loopback redirect,
all rejected.

The rejection happens before Septeo reads the document. A request-logging URL
(webhook.site) served as the client id received no request from Septeo, only
the operator's own check. So Septeo filters the identifier itself (an allowlist
of client URLs or hosts), not the document's content.

## What would unblock it

1. **Ask Septeo to accept Prestance's client id.** Host the metadata document
   on a stable Prestance domain, then ask Tech-expert@septeo.com to add that
   URL. Once added, the flow is standard OAuth with PKCE and a loopback or
   HTTPS redirect. `probe.sh` will show `LOGIN` for it.
2. **Run Claude Code itself as the client** (the Claude Agent SDK is Claude
   Code). It is accepted today. The connection then lives in that Claude Code
   session's config, and the user must complete the login once in a browser
   that can reach the session's loopback redirect.

Do not reuse Claude's client id from our own code. That presents Prestance as
Claude to Septeo.
