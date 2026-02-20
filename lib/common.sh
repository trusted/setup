#!/bin/bash
#
# Shared helpers for Trusted Setup.
# Sourced by setup.sh — do not execute directly.

# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

# Colors (disabled when output is not a terminal)
if [ -t 1 ]; then
  # shellcheck disable=SC2034 # COLOR_RED is used by setup.sh and doctor.sh
  COLOR_RED=$'\033[31m'
  COLOR_GREEN=$'\033[32m'
  COLOR_YELLOW=$'\033[33m'
  COLOR_RESET=$'\033[0m'
else
  # shellcheck disable=SC2034
  COLOR_RED=""
  COLOR_GREEN=""
  COLOR_YELLOW=""
  COLOR_RESET=""
fi

fmt_header() {
  echo ""
  echo "== $1 =="
}

fmt_ok() {
  echo "  ${COLOR_GREEN}[ok]${COLOR_RESET} $1"
}

fmt_install() {
  echo "  ${COLOR_YELLOW}[install]${COLOR_RESET} $1"
}

# ---------------------------------------------------------------------------
# Tool detection
# ---------------------------------------------------------------------------

cmd_exists() {
  command -v "$1" > /dev/null 2>&1
}

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------

detect_os() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
          ubuntu|debian)
            echo "ubuntu"
            ;;
          arch|endeavouros|manjaro)
            echo "arch"
            ;;
          *)
            echo "unsupported"
            ;;
        esac
      else
        echo "unsupported"
      fi
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

OS="$(detect_os)"

if [ "$OS" = "unsupported" ]; then
  echo "ERROR: Unsupported operating system."
  echo "Supported: macOS, Ubuntu/Debian, Arch Linux (including Omarchy)."
  exit 1
fi
