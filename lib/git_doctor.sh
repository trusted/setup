#!/bin/bash
#
# Doctor check: git and GitHub CLI.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

# ---------------------------------------------------------------------------
# git
# ---------------------------------------------------------------------------

fmt_header "git"

check_cmd "git" "git"

if cmd_exists git; then
  version_output="$(git --version 2>&1)"
  if [[ "$version_output" == *"git version"* ]]; then
    check_pass "git reports version: $version_output"
  else
    check_fail "git --version returned unexpected output: $version_output"
  fi
fi

# ---------------------------------------------------------------------------
# GitHub CLI (gh)
# ---------------------------------------------------------------------------

fmt_header "GitHub CLI (gh)"

check_cmd "gh" "gh"

if cmd_exists gh; then
  version_output="$(gh --version 2>&1 | head -1)"
  if [[ "$version_output" == *"gh version"* ]]; then
    check_pass "gh reports version: $version_output"
  else
    check_fail "gh --version returned unexpected output: $version_output"
  fi
fi
