#!/bin/bash
#
# Doctor check: Work directory and cloned repositories.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_warn)

fmt_header "Work Directory"

if [ -d "$HOME/Work" ]; then
  check_pass "$HOME/Work directory exists"
else
  check_fail "$HOME/Work directory does not exist"
fi

if [ -d "$HOME/Work/setup/.git" ]; then
  check_pass "setup is cloned to $HOME/Work/setup"
else
  check_warn "setup not found at $HOME/Work/setup (ok if running from another location)"
fi

if [ -f "$HOME/Work/setup/setup.sh" ]; then
  check_pass "$HOME/Work/setup contains setup.sh"
else
  check_warn "setup.sh not found in $HOME/Work/setup"
fi

if [ -d "$HOME/Work/docs/.git" ]; then
  check_pass "docs is cloned to $HOME/Work/docs"
else
  check_warn "docs not found at $HOME/Work/docs (may not have been cloned yet)"
fi
