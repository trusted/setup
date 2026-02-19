#!/bin/bash
#
# Doctor check: private registry configuration.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_warn)

fmt_header "Private Registries (Bundler)"

if cmd_exists bundle; then
  # Check Sidekiq Enterprise (contribsys) credential
  if bundle config get enterprise.contribsys.com 2>/dev/null | grep -q "Set for"; then
    check_pass "bundler: enterprise.contribsys.com is configured"
  else
    check_fail "bundler: enterprise.contribsys.com is not configured"
  fi

  # Check GitHub Packages gem registry credential
  if bundle config get rubygems.pkg.github.com 2>/dev/null | grep -q "Set for"; then
    check_pass "bundler: rubygems.pkg.github.com is configured"
  else
    check_fail "bundler: rubygems.pkg.github.com is not configured"
  fi

  # Check GitHub git sources credential
  if bundle config get github.com 2>/dev/null | grep -q "Set for"; then
    check_pass "bundler: github.com is configured"
  else
    check_fail "bundler: github.com is not configured"
  fi
else
  check_fail "Cannot check Bundler registries — bundle is not installed"
fi

fmt_header "Private Registries (Yarn)"

if cmd_exists yarn; then
  # Check @trusted scope
  if yarn config get npmScopes.trusted 2>/dev/null | grep -q "npm.pkg.github.com"; then
    check_pass "yarn: @trusted scope is configured (npm.pkg.github.com)"
  else
    check_fail "yarn: @trusted scope is not configured"
  fi

  # Check @fortawesome scope
  if yarn config get npmScopes.fortawesome 2>/dev/null | grep -q "npm.fontawesome.com"; then
    check_pass "yarn: @fortawesome scope is configured (npm.fontawesome.com)"
  else
    check_fail "yarn: @fortawesome scope is not configured"
  fi
else
  check_fail "Cannot check Yarn registries — yarn is not installed"
fi
