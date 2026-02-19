#!/bin/bash
#
# Trusted Dev Setup — Doctor
#
# Read-only diagnostic script that verifies all tools and configuration
# installed by setup.sh are present and working. Never modifies anything.
#
# Usage:
#   bash doctor.sh
#
# Exit codes:
#   0 — All checks passed
#   1 — One or more checks failed

set -uo pipefail

# ---------------------------------------------------------------------------
# Resolve script directory
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Load shared helpers (OS detection, cmd_exists, formatting)
# ---------------------------------------------------------------------------

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ---------------------------------------------------------------------------
# Doctor helpers
# ---------------------------------------------------------------------------

FAIL_COUNT=0
PASS_COUNT=0
WARN_COUNT=0

check_pass() {
  echo "  [ok] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
  echo "  [FAIL] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_warn() {
  echo "  [warn] $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

# Check that a command exists
check_cmd() {
  local name="$1"
  local cmd="${2:-$1}"

  if cmd_exists "$cmd"; then
    check_pass "$name is installed"
  else
    check_fail "$name is not installed"
  fi
}

# ---------------------------------------------------------------------------
# Run checks
# ---------------------------------------------------------------------------

echo ""
echo "= Trusted Dev Setup Doctor ="
echo ""
echo "  Platform: $OS"
echo ""

# shellcheck source=lib/packages_doctor.sh
source "$SCRIPT_DIR/lib/packages_doctor.sh"

# shellcheck source=lib/git_doctor.sh
source "$SCRIPT_DIR/lib/git_doctor.sh"

# shellcheck source=lib/mise_doctor.sh
source "$SCRIPT_DIR/lib/mise_doctor.sh"

# shellcheck source=lib/1password_doctor.sh
source "$SCRIPT_DIR/lib/1password_doctor.sh"

# shellcheck source=lib/build_doctor.sh
source "$SCRIPT_DIR/lib/build_doctor.sh"

# shellcheck source=lib/docker_doctor.sh
source "$SCRIPT_DIR/lib/docker_doctor.sh"

# shellcheck source=lib/aws_doctor.sh
source "$SCRIPT_DIR/lib/aws_doctor.sh"

# shellcheck source=lib/migrate_doctor.sh
source "$SCRIPT_DIR/lib/migrate_doctor.sh"

# shellcheck source=lib/repos_doctor.sh
source "$SCRIPT_DIR/lib/repos_doctor.sh"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "= Doctor Summary ="
echo ""
echo "  Passed:   $PASS_COUNT"
echo "  Failed:   $FAIL_COUNT"
echo "  Warnings: $WARN_COUNT"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "Some checks failed. Run setup.sh to fix them:"
  echo "  bash setup.sh"
  echo ""
  exit 1
else
  echo "All checks passed. Your environment is healthy."
  echo ""
  exit 0
fi
