#!/bin/bash
#
# Rename devsetup -> setup.
#
# The project was renamed from trusted/devsetup to trusted/setup.
# This migration moves:
#   1. State directory: ~/.local/state/trusted/devsetup/ -> ~/.local/state/trusted/setup/
#   2. Clone directory: ~/Work/devsetup/ -> ~/Work/setup/

set -euo pipefail

OLD_STATE_DIR="$HOME/.local/state/trusted/devsetup"
NEW_STATE_DIR="$HOME/.local/state/trusted/setup"

# --- State directory ---

if [ -d "$OLD_STATE_DIR" ] && [ ! -d "$NEW_STATE_DIR" ]; then
  mv "$OLD_STATE_DIR" "$NEW_STATE_DIR"
  echo "  Moved state directory: $OLD_STATE_DIR -> $NEW_STATE_DIR"
elif [ -d "$NEW_STATE_DIR" ]; then
  echo "  State directory already at $NEW_STATE_DIR (skipping)"
else
  echo "  No old state directory found at $OLD_STATE_DIR (skipping)"
fi

# Clean up empty parent if nothing else lives under trusted/devsetup
if [ -d "$OLD_STATE_DIR" ] && [ -z "$(ls -A "$OLD_STATE_DIR" 2>/dev/null)" ]; then
  rmdir "$OLD_STATE_DIR" 2>/dev/null || true
fi

# --- Clone directory ---

OLD_CLONE_DIR="$HOME/Work/devsetup"
NEW_CLONE_DIR="$HOME/Work/setup"

if [ -d "$OLD_CLONE_DIR/.git" ] && [ ! -d "$NEW_CLONE_DIR" ]; then
  mv "$OLD_CLONE_DIR" "$NEW_CLONE_DIR"
  echo "  Moved clone directory: $OLD_CLONE_DIR -> $NEW_CLONE_DIR"

  # Update git remote to new repo URL
  if git -C "$NEW_CLONE_DIR" remote get-url origin 2>/dev/null | grep -q "devsetup"; then
    git -C "$NEW_CLONE_DIR" remote set-url origin "https://github.com/trusted/setup.git"
    echo "  Updated git remote origin to trusted/setup"
  fi
elif [ -d "$NEW_CLONE_DIR" ]; then
  echo "  Clone directory already at $NEW_CLONE_DIR (skipping)"
else
  echo "  No old clone directory found at $OLD_CLONE_DIR (skipping)"
fi
