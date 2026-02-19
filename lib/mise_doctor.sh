#!/bin/bash
#
# Doctor check: mise and Ruby.
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
