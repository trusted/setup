#!/bin/bash
#
# CircleCI CLI setup and authentication.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

# ---------------------------------------------------------------------------
# CircleCI CLI
# ---------------------------------------------------------------------------

fmt_header "CircleCI CLI"

if cmd_exists circleci; then
  fmt_ok "circleci already installed ($(circleci version 2>/dev/null | head -1))"
else
  fmt_install "CircleCI CLI"
  case "$OS" in
    macos)
      brew install circleci
      ;;
    ubuntu|arch)
      # Official installer — works on any Linux
      curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/main/install.sh | sudo bash
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# CircleCI Authentication
# ---------------------------------------------------------------------------

fmt_header "CircleCI Authentication"

if circleci diagnostic 2>&1 | grep -q "OK, got a token"; then
  fmt_ok "CircleCI CLI: already authenticated"
else
  echo "  CircleCI CLI needs to be configured."
  echo "  You will need a personal API token from:"
  echo "  https://app.circleci.com/settings/user/tokens"
  echo ""
  circleci setup

  if ! circleci diagnostic 2>&1 | grep -q "OK, got a token"; then
    echo ""
    echo "ERROR: CircleCI CLI authentication failed or was cancelled."
    echo "Setup cannot continue without CircleCI access."
    exit 1
  fi
  fmt_ok "CircleCI CLI: authenticated"
fi
