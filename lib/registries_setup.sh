#!/bin/bash
#
# Private registry configuration for Bundler and Yarn.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh, gh authenticated (with read:packages scope),
#           op authenticated, bundle on PATH, yarn on PATH.

fmt_header "Private Registries"

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
# Yarn: @trusted npm scope (GitHub Packages)
# ---------------------------------------------------------------------------

yarn config set --home npmScopes.trusted.npmRegistryServer https://npm.pkg.github.com > /dev/null 2>&1
yarn config set --home npmScopes.trusted.npmAuthToken "$gh_token" > /dev/null 2>&1
fmt_ok "yarn: @trusted (npm.pkg.github.com)"

# ---------------------------------------------------------------------------
# Yarn: @fortawesome npm scope (Font Awesome, key from 1Password)
# ---------------------------------------------------------------------------

fa_token="$(op item get --vault 'Team: Engineering' \
  'Font Awesome' --field 'npm key' 2>/dev/null)"
if [ -z "$fa_token" ]; then
  echo ""
  echo "ERROR: Could not retrieve Font Awesome npm token from 1Password."
  echo "Verify you have access to the 'Team: Engineering' vault."
  exit 1
fi

yarn config set --home npmScopes.fortawesome.npmRegistryServer https://npm.fontawesome.com/ > /dev/null 2>&1
yarn config set --home npmScopes.fortawesome.npmAuthToken "$fa_token" > /dev/null 2>&1
fmt_ok "yarn: @fortawesome (npm.fontawesome.com)"
