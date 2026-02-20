#!/bin/bash
#
# Doctor check: Migration state and pending migrations.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail)
# Expects: SCRIPT_DIR to be set by the caller.

fmt_header "Migrations"

MIGRATION_STATE_DIR="$HOME/.local/state/trusted/setup/migrations"

if [ -d "$MIGRATION_STATE_DIR" ]; then
  check_pass "Migration state directory exists"
else
  check_fail "Migration state directory missing ($MIGRATION_STATE_DIR)"
fi

# Check for pending migrations
migrations_dir="$SCRIPT_DIR/migrations"
pending_count=0
pending_names=()

for file in "$migrations_dir"/*.sh; do
  [ -f "$file" ] || continue

  filename="$(basename "$file")"

  if [ ! -f "$MIGRATION_STATE_DIR/$filename" ]; then
    pending_count=$((pending_count + 1))
    pending_names+=("${filename%.sh}")
  fi
done

if [ "$pending_count" -eq 0 ]; then
  check_pass "No pending migrations"
else
  check_fail "$pending_count pending migration(s): ${pending_names[*]}"
  echo "         Run setup.sh to apply them."
fi
