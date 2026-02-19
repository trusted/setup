#!/bin/bash
#
# Doctor check: AWS CLI and AWS VPN Client.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

# ---------------------------------------------------------------------------
# AWS CLI
# ---------------------------------------------------------------------------

fmt_header "AWS CLI"

check_cmd "AWS CLI" "aws"

if cmd_exists aws; then
  version_output="$(aws --version 2>&1)"
  if [[ "$version_output" == *"aws-cli"* ]]; then
    check_pass "AWS CLI reports version: $version_output"
  else
    check_fail "aws --version returned unexpected output: $version_output"
  fi
fi

# ---------------------------------------------------------------------------
# AWS VPN Client
# ---------------------------------------------------------------------------

fmt_header "AWS VPN Client"

case "$OS" in
  macos)
    if [ -d "/Applications/AWS VPN Client" ] || [ -d "/Applications/AWS VPN Client.app" ]; then
      check_pass "AWS VPN Client is installed"
    else
      check_fail "AWS VPN Client is not installed"
    fi
    ;;
  ubuntu|arch)
    if cmd_exists awsvpnclient; then
      check_pass "AWS VPN Client is installed"
    else
      check_fail "AWS VPN Client is not installed"
    fi
    ;;
esac
