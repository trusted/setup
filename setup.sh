#!/bin/bash
#
# Trusted Dev Setup
#
# Bootstraps a developer machine with the baseline tools required to clone
# and run any Trusted project's bin/setup script.
#
# Usage:
#   # First-time setup or update
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/devsetup/main/setup.sh)"
#
#   # Re-run a specific migration
#   ./setup.sh --rerun <timestamp>

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve script directory (works for both local execution and curl pipe)
# ---------------------------------------------------------------------------

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Running via curl | bash — clone (or update) the repo at ~/Work/devsetup
  DEVSETUP_CLONE_DIR="$HOME/Work/devsetup"
  DEVSETUP_REPO="${DEVSETUP_REPO:-trusted/devsetup}"
  DEVSETUP_REF="${DEVSETUP_REF:-main}"

  if [ -d "$DEVSETUP_CLONE_DIR/.git" ]; then
    # Abort if there are uncommitted changes
    if ! git -C "$DEVSETUP_CLONE_DIR" diff --quiet HEAD 2>/dev/null; then
      echo "ERROR: $DEVSETUP_CLONE_DIR has uncommitted changes."
      echo "Commit or stash them, then re-run setup."
      exit 1
    fi

    # Abort if on the wrong branch
    local_branch="$(git -C "$DEVSETUP_CLONE_DIR" branch --show-current)"
    if [ "$local_branch" != "$DEVSETUP_REF" ]; then
      echo "ERROR: $DEVSETUP_CLONE_DIR is on branch '$local_branch', expected '$DEVSETUP_REF'."
      echo "Switch to $DEVSETUP_REF, then re-run setup."
      exit 1
    fi

    echo "Updating devsetup from github.com/$DEVSETUP_REPO ($DEVSETUP_REF)..."
    git -C "$DEVSETUP_CLONE_DIR" pull --ff-only --quiet
  else
    echo "Cloning devsetup from github.com/$DEVSETUP_REPO ($DEVSETUP_REF)..."
    mkdir -p "$HOME/Work"
    git clone "https://github.com/$DEVSETUP_REPO.git" "$DEVSETUP_CLONE_DIR" --quiet
    git -C "$DEVSETUP_CLONE_DIR" checkout "$DEVSETUP_REF" --quiet
  fi

  SCRIPT_DIR="$DEVSETUP_CLONE_DIR"
fi

# ---------------------------------------------------------------------------
# Load shared helpers and OS detection
# ---------------------------------------------------------------------------

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# shellcheck source=lib/migrate.sh
source "$SCRIPT_DIR/lib/migrate.sh"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

ACTION="setup"
RERUN_TIMESTAMP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rerun)
      ACTION="rerun"
      RERUN_TIMESTAMP="${2:-}"
      if [ -z "$RERUN_TIMESTAMP" ]; then
        echo "ERROR: --rerun requires a migration timestamp."
        echo "Usage: setup.sh --rerun <timestamp>"
        exit 1
      fi
      shift 2
      ;;
    --help|-h)
      echo "Trusted Dev Setup"
      echo ""
      echo "Usage: setup.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --rerun <timestamp>    Re-run a specific migration"
      echo "  --help                 Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run setup.sh --help for usage."
      exit 1
      ;;
  esac
done

# Handle --rerun before anything else
if [ "$ACTION" = "rerun" ]; then
  rerun_migration "$SCRIPT_DIR" "$RERUN_TIMESTAMP"
  exit $?
fi

# ---------------------------------------------------------------------------
# Run setup
# ---------------------------------------------------------------------------

echo ""
echo "= Trusted Dev Setup ="
echo ""
echo "  Platform: $OS"
echo ""

# shellcheck source=lib/setup_packages.sh
source "$SCRIPT_DIR/lib/setup_packages.sh"

# shellcheck source=lib/setup_git.sh
source "$SCRIPT_DIR/lib/setup_git.sh"

# shellcheck source=lib/setup_mise.sh
source "$SCRIPT_DIR/lib/setup_mise.sh"

# shellcheck source=lib/setup_1password.sh
source "$SCRIPT_DIR/lib/setup_1password.sh"

# shellcheck source=lib/setup_build.sh
source "$SCRIPT_DIR/lib/setup_build.sh"

# shellcheck source=lib/setup_docker.sh
source "$SCRIPT_DIR/lib/setup_docker.sh"

# shellcheck source=lib/setup_aws.sh
source "$SCRIPT_DIR/lib/setup_aws.sh"

# ---------------------------------------------------------------------------
# Migrations
# ---------------------------------------------------------------------------

fmt_header "Migrations"

run_migrations "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# Repositories
# ---------------------------------------------------------------------------

# shellcheck source=lib/setup_repos.sh
source "$SCRIPT_DIR/lib/setup_repos.sh"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "= Trusted Dev Setup Complete ="
echo ""
echo "Next steps:"
echo "  1. Open a new terminal (or run: source ~/.zshrc)"
echo "  2. Clone a project:  cd ~/Work && gh repo clone trusted/<repo-name>"
echo "  3. Run project setup: cd <repo-name> && bin/setup"
echo ""
