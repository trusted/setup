#!/bin/bash
#
# Private registry configuration for Bundler and Yarn.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh, gh authenticated (with read:packages scope),
#           op authenticated, Ruby + Node installed via mise.

fmt_header "Private Registries"

# ---------------------------------------------------------------------------
# Ensure mise-managed tools (bundle, yarn) are available in this session.
# mise activate may not have fully populated PATH with shims yet, so we
# add the shims directory explicitly.
# ---------------------------------------------------------------------------

export PATH="$HOME/.local/share/mise/shims:$PATH"

# ---------------------------------------------------------------------------
# GitHub credentials (used by both Bundler and Yarn)
# ---------------------------------------------------------------------------

gh_token="$(gh auth token 2>/dev/null)"
if [ -z "$gh_token" ]; then
  echo ""
  echo "ERROR: Could not retrieve GitHub token."
  echo "Run 'gh auth login --scopes read:packages,write:packages' first."
  exit 1
fi

gh_user="$(gh api user --jq .login 2>/dev/null)"
if [ -z "$gh_user" ]; then
  echo ""
  echo "ERROR: Could not retrieve GitHub username."
  exit 1
fi

# ---------------------------------------------------------------------------
# Bundler: Sidekiq Enterprise (contribsys key from 1Password)
# ---------------------------------------------------------------------------

contribsys_key="$(op item get --vault 'Team: Engineering' \
  BUNDLE_ENTERPRISE__CONTRIBSYS__COM --field 'license key' 2>/dev/null)"
if [ -z "$contribsys_key" ]; then
  echo ""
  echo "ERROR: Could not retrieve Contribsys (Sidekiq Enterprise) key from 1Password."
  echo "Verify you have access to the 'Team: Engineering' vault."
  exit 1
fi

bundle config set --global enterprise.contribsys.com "$contribsys_key" > /dev/null
fmt_ok "bundler: enterprise.contribsys.com"

# ---------------------------------------------------------------------------
# Bundler: GitHub Packages gem registry (user:token format)
# ---------------------------------------------------------------------------

bundle config set --global rubygems.pkg.github.com "$gh_user:$gh_token" > /dev/null
fmt_ok "bundler: rubygems.pkg.github.com"

# ---------------------------------------------------------------------------
# Bundler: GitHub git sources (private forks / private gem repos)
# ---------------------------------------------------------------------------

bundle config set --global github.com "$gh_token" > /dev/null
fmt_ok "bundler: github.com"

# ---------------------------------------------------------------------------
# Yarn: private npm scopes (@trusted, @fortawesome)
#
# Write directly to ~/.yarnrc.yml (Yarn Berry's home config). This avoids
# depending on which yarn binary is on PATH — Yarn Classic (v1) does not
# support the --home flag or npmScopes. Writing the YAML file works
# regardless of the active yarn version.
# ---------------------------------------------------------------------------

fa_token="$(op item get --vault 'Team: Engineering' \
  'Font Awesome' --field 'npm key' 2>/dev/null)"
if [ -z "$fa_token" ]; then
  echo ""
  echo "ERROR: Could not retrieve Font Awesome npm token from 1Password."
  echo "Verify you have access to the 'Team: Engineering' vault."
  exit 1
fi

YARNRC_FILE="$HOME/.yarnrc.yml"

# Build the npmScopes block. We overwrite the file each time to ensure
# credentials stay current. Any pre-existing content that is NOT managed
# by devsetup will be lost — this is intentional; ~/.yarnrc.yml is owned
# by devsetup for scope configuration.
cat > "$YARNRC_FILE" <<EOF
npmScopes:
  trusted:
    npmRegistryServer: "https://npm.pkg.github.com"
    npmAuthToken: "${gh_token}"
  fortawesome:
    npmRegistryServer: "https://npm.fontawesome.com/"
    npmAuthToken: "${fa_token}"
EOF

fmt_ok "yarn: @trusted (npm.pkg.github.com)"
fmt_ok "yarn: @fortawesome (npm.fontawesome.com)"
