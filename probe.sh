#!/usr/bin/env bash
# Asks passport.secib.fr (Septeo Legal MCP's auth server) to start a login for
# each client_id. "LOGIN" = the client is accepted (Septeo's login page opens);
# "REJECTED" = Septeo's error page. No account is needed: it stops before login.
set -euo pipefail

probe() {
  local name=$1 client_id=$2 redirect=$3 loc
  loc=$(curl -s -i -m 20 -G https://passport.secib.fr/connect/authorize \
    --data-urlencode "client_id=$client_id" \
    --data-urlencode "redirect_uri=$redirect" \
    --data-urlencode "response_type=code" \
    --data-urlencode "scope=openid profile offline_access dossier.read" \
    --data-urlencode "code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM" \
    --data-urlencode "code_challenge_method=S256" \
    --data-urlencode "state=probe" \
    --data-urlencode "resource=https://ssa-mcp.septeo.fr/mcp" |
    grep -i '^location' || true)
  case $loc in
    */Account/Login*) echo "LOGIN     $name" ;;
    */error*) echo "REJECTED  $name" ;;
    *) echo "UNKNOWN   $name: $loc" ;;
  esac
}

probe "Claude (web)" https://claude.ai/oauth/mcp-oauth-client-metadata https://claude.ai/api/mcp/auth_callback
probe "Claude Code" https://claude.ai/oauth/claude-code-client-metadata http://localhost/callback
probe "VS Code" https://vscode.dev/oauth/client-metadata.json https://vscode.dev/redirect
probe "Prestance" https://jiliac.github.io/septeo-spike/oauth/client-metadata.json http://localhost/callback
