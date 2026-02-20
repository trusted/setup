#!/bin/bash
#
# Doctor check: private registry configuration.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_warn)

fmt_header "Private Registries (Bundler)"

# Read ~/.bundle/config directly instead of using `bundle config get` because
# Bundler creates/modifies the config file as a side effect of any config
# command, violating the doctor's read-only contract.
BUNDLE_CONFIG="$HOME/.bundle/config"

if [ -f "$BUNDLE_CONFIG" ]; then
  # Check Sidekiq Enterprise (contribsys) credential
  if grep -q "BUNDLE_ENTERPRISE__CONTRIBSYS__COM" "$BUNDLE_CONFIG" 2>/dev/null; then
    check_pass "bundler: enterprise.contribsys.com is configured"
  else
    check_fail "bundler: enterprise.contribsys.com is not configured"
  fi

  # Check GitHub Packages gem registry credential
  if grep -q "BUNDLE_RUBYGEMS__PKG__GITHUB__COM" "$BUNDLE_CONFIG" 2>/dev/null; then
    check_pass "bundler: rubygems.pkg.github.com is configured"
  else
    check_fail "bundler: rubygems.pkg.github.com is not configured"
  fi

  # Check GitHub git sources credential
  if grep -q "BUNDLE_GITHUB__COM" "$BUNDLE_CONFIG" 2>/dev/null; then
    check_pass "bundler: github.com is configured"
  else
    check_fail "bundler: github.com is not configured"
  fi
else
  check_fail "Bundler config not found at $BUNDLE_CONFIG (run setup.sh)"
fi

fmt_header "Private Registries (Yarn)"

# Yarn Berry reads scope config from ~/.yarnrc.yml (written by registries_setup.sh).
# We check the file directly rather than using `yarn config get` because Yarn
# Classic (v1) does not understand npmScopes.
YARNRC_FILE="$HOME/.yarnrc.yml"

if [ -f "$YARNRC_FILE" ]; then
  # Check @trusted scope
  if grep -q "npm.pkg.github.com" "$YARNRC_FILE" 2>/dev/null; then
    check_pass "yarn: @trusted scope is configured (npm.pkg.github.com)"
  else
    check_fail "yarn: @trusted scope is not configured in $YARNRC_FILE"
  fi

  # Check @fortawesome scope
  if grep -q "npm.fontawesome.com" "$YARNRC_FILE" 2>/dev/null; then
    check_pass "yarn: @fortawesome scope is configured (npm.fontawesome.com)"
  else
    check_fail "yarn: @fortawesome scope is not configured in $YARNRC_FILE"
  fi
else
  check_fail "Yarn scope config not found at $YARNRC_FILE (run setup.sh)"
fi
