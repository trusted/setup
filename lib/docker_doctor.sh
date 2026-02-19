#!/bin/bash
#
# Doctor check: Docker, Docker Compose, and Colima.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

fmt_header "Docker"

check_cmd "Docker" "docker"

if cmd_exists docker; then
  version_output="$(docker --version 2>&1)"
  if [[ "$version_output" == *"Docker"* ]]; then
    check_pass "Docker reports version: $version_output"
  else
    check_fail "docker --version returned unexpected output: $version_output"
  fi
fi

# ---------------------------------------------------------------------------
# Docker Compose
# ---------------------------------------------------------------------------

fmt_header "Docker Compose"

if cmd_exists docker && docker compose version > /dev/null 2>&1; then
  version_output="$(docker compose version --short 2>&1)"
  check_pass "Docker Compose is installed: $version_output"
else
  check_fail "Docker Compose is not installed (docker compose not available)"
fi

# ---------------------------------------------------------------------------
# Colima (macOS only)
# ---------------------------------------------------------------------------

if [ "$OS" = "macos" ]; then
  fmt_header "Colima"
  check_cmd "Colima" "colima"
fi
