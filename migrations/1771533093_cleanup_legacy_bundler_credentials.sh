#!/bin/bash
#
# Clean up legacy full-URL bundler credential keys.
#
# Older setups (or manual configuration) stored GitHub Packages credentials
# using the full-URL format:
#   BUNDLE_HTTPS://RUBYGEMS__PKG__GITHUB__COM/TRUSTED/
#
# setup.sh now uses the host-only format (rubygems.pkg.github.com), which is
# broader in scope and matches Bundler's documented convention. Both formats
# work, but having the legacy key lingering causes inconsistency across
# machines and confuses doctor.sh checks.
#
# This migration removes legacy full-URL keys. The correct host-only keys
# are set by registries_setup.sh, which runs before migrations.

BUNDLE_CONFIG="$HOME/.bundle/config"

if [ ! -f "$BUNDLE_CONFIG" ]; then
  echo "  No ~/.bundle/config found — nothing to clean up."
  exit 0
fi

# Remove legacy full-URL GitHub Packages credential
if grep -q 'BUNDLE_HTTPS://RUBYGEMS__PKG__GITHUB__COM' "$BUNDLE_CONFIG" 2>/dev/null; then
  bundle config unset --global "https://rubygems.pkg.github.com/trusted/" > /dev/null 2>&1
  echo "  Removed legacy key: https://rubygems.pkg.github.com/trusted/"
else
  echo "  No legacy GitHub Packages key found — skipping."
fi

# Remove stray BUNDLE_GET entry (likely a misconfigured credential)
if grep -q '^BUNDLE_GET:' "$BUNDLE_CONFIG" 2>/dev/null; then
  # bundle config doesn't support unsetting arbitrary keys cleanly,
  # so we remove the line directly.
  sed -i.bak '/^BUNDLE_GET:/d' "$BUNDLE_CONFIG"
  rm -f "${BUNDLE_CONFIG}.bak"
  echo "  Removed stray BUNDLE_GET entry."
else
  echo "  No stray BUNDLE_GET entry — skipping."
fi
