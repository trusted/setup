#!/bin/bash
#
# Switch the global mise Node.js version from "latest" to "lts".
#
# Node.js 25+ removed corepack, which breaks yarn installation.
# This migration ensures existing machines are moved to LTS as the
# global default, matching what setup.sh now enforces.

if ! command -v mise > /dev/null 2>&1; then
  echo "  mise not found — skipping (will be handled by setup)."
  exit 0
fi

current="$(mise current node 2>/dev/null || true)"

if [[ "$current" == 25.* || "$current" == 26.* ]]; then
  echo "  Global node is $current (post-corepack removal). Switching to LTS."
  mise use --global node@lts
  echo "  Global node is now: $(mise exec -- node --version)"

  # Re-enable corepack/yarn under the new LTS node
  if mise exec -- corepack --version > /dev/null 2>&1; then
    mise exec -- corepack enable
    mise reshim 2>/dev/null || true
    echo "  corepack re-enabled, yarn shims updated."
  fi
else
  echo "  Global node is ${current:-not set} — no change needed."
fi
