#!/bin/bash
#
# Migration runner for Trusted Dev Setup.
# Sourced by setup.sh — do not execute directly.
#
# Inspired by Omarchy's migration system:
# https://github.com/basecamp/omarchy/blob/dev/bin/omarchy-migrate

MIGRATION_STATE_DIR="$HOME/.local/state/trusted/devsetup/migrations"

run_migrations() {
  local script_dir="$1"
  local migrations_dir="$script_dir/migrations"

  mkdir -p "$MIGRATION_STATE_DIR"

  # Check if there are any migration files
  local has_migrations=false
  for file in "$migrations_dir"/*.sh; do
    [ -f "$file" ] && has_migrations=true && break
  done

  if [ "$has_migrations" = false ]; then
    echo "No migrations found."
    return 0
  fi

  local pending=0
  local applied=0

  for file in "$migrations_dir"/*.sh; do
    [ -f "$file" ] || continue

    local filename
    filename=$(basename "$file")
    local migration_name="${filename%.sh}"

    if [ -f "$MIGRATION_STATE_DIR/$filename" ]; then
      applied=$((applied + 1))
      continue
    fi

    pending=$((pending + 1))

    echo "-> Running migration $migration_name ..."

    if bash "$file"; then
      touch "$MIGRATION_STATE_DIR/$filename"
      echo "   Migration $migration_name completed."
    else
      echo ""
      echo "ERROR: Migration $migration_name failed."
      echo "Fix the issue and re-run setup.sh."
      echo "To retry just this migration: setup.sh --rerun ${migration_name%%_*}"
      return 1
    fi
  done

  if [ "$pending" -eq 0 ]; then
    echo "All migrations already applied ($applied total)."
  else
    echo "Applied $pending new migration(s) ($((applied + pending)) total)."
  fi
}

rerun_migration() {
  local script_dir="$1"
  local timestamp="$2"
  local migrations_dir="$script_dir/migrations"

  mkdir -p "$MIGRATION_STATE_DIR"

  # Find the migration file by timestamp prefix (supports <timestamp>_<name>.sh)
  local filepath=""
  for candidate in "$migrations_dir/${timestamp}"*.sh; do
    if [ -f "$candidate" ]; then
      filepath="$candidate"
      break
    fi
  done

  if [ -z "$filepath" ]; then
    echo "ERROR: No migration file found matching timestamp: $timestamp"
    return 1
  fi

  local filename
  filename="$(basename "$filepath")"

  # Remove the marker file if it exists
  rm -f "$MIGRATION_STATE_DIR/$filename"

  local migration_name="${filename%.sh}"

  echo "-> Re-running migration $migration_name ..."

  if bash "$filepath"; then
    touch "$MIGRATION_STATE_DIR/$filename"
    echo "   Migration $migration_name completed."
  else
    echo ""
    echo "ERROR: Migration $migration_name failed."
    return 1
  fi
}
