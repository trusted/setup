#!/bin/bash
#
# Doctor check: 1Password CLI.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

fmt_header "1Password CLI (op)"

check_cmd "op" "op"

if cmd_exists op; then
  version_output="$(op --version 2>&1)"
  check_pass "op reports version: $version_output"
fi
