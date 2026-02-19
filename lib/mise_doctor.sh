#!/bin/bash
#
# Doctor check: mise, Ruby, Node.js, and Yarn.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

# ---------------------------------------------------------------------------
# mise
# ---------------------------------------------------------------------------

fmt_header "mise"

check_cmd "mise" "mise"

if cmd_exists mise; then
  version_output="$(mise --version 2>&1)"
  check_pass "mise reports version: $version_output"
fi

# ---------------------------------------------------------------------------
# Ruby (via mise)
# ---------------------------------------------------------------------------

fmt_header "Ruby (via mise)"

if cmd_exists mise; then
  if mise which ruby > /dev/null 2>&1; then
    check_pass "Ruby is available via mise"
    ruby_version="$(mise exec -- ruby --version 2>&1)"
    if [[ "$ruby_version" == *"ruby"* ]]; then
      check_pass "Ruby executes and reports version: $ruby_version"
    else
      check_fail "Ruby returned unexpected output: $ruby_version"
    fi
  else
    check_fail "Ruby is not available via mise (expected global default)"
  fi
else
  check_fail "Cannot check Ruby — mise is not installed"
fi

# ---------------------------------------------------------------------------
# Node.js (via mise)
# ---------------------------------------------------------------------------

fmt_header "Node.js (via mise)"

if cmd_exists mise; then
  if mise which node > /dev/null 2>&1; then
    check_pass "Node.js is available via mise"
    node_version="$(mise exec -- node --version 2>&1)"
    if [[ "$node_version" == v* ]]; then
      check_pass "Node.js executes and reports version: $node_version"
    else
      check_fail "Node.js returned unexpected output: $node_version"
    fi
  else
    check_fail "Node.js is not available via mise (expected global default)"
  fi
else
  check_fail "Cannot check Node.js — mise is not installed"
fi

# ---------------------------------------------------------------------------
# Yarn (via corepack)
# ---------------------------------------------------------------------------

fmt_header "Yarn (via corepack)"

if cmd_exists yarn; then
  check_pass "yarn is installed"
  yarn_version="$(yarn --version 2>&1)"
  check_pass "yarn reports version: $yarn_version"
else
  check_fail "yarn is not installed (expected via corepack)"
fi
