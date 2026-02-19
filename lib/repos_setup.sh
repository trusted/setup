#!/bin/bash
#
# Work directory and repository cloning.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

WORK_DIR="$HOME/Work"

fmt_header "Work Directory"

mkdir -p "$WORK_DIR"
fmt_ok "$WORK_DIR ready"

clone_to_work() {
  local repo="$1"
  local name="$2"
  local dir="$WORK_DIR/$name"

  if [ -d "$dir/.git" ]; then
    fmt_ok "$name already at $dir"
  elif gh auth status > /dev/null 2>&1; then
    fmt_install "Cloning $name to $dir"
    gh repo clone "$repo" "$dir" -- --quiet
  fi
}

clone_to_work "trusted/docs" "docs"
