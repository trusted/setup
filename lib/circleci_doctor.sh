#!/bin/bash
#
# Doctor check: CircleCI CLI.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

fmt_header "CircleCI CLI"

check_cmd "circleci" "circleci"

if cmd_exists circleci; then
  version_output="$(circleci version 2>&1 | head -1)"
  check_pass "circleci reports version: $version_output"

  circleci_diag="$(circleci diagnostic 2>&1 || true)"
  if echo "$circleci_diag" | grep -q "OK, got a token"; then
    check_pass "circleci is authenticated"
  else
    check_fail "circleci is not authenticated (run: circleci setup)"
  fi
fi
