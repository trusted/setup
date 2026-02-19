#!/bin/bash
#
# Shared helpers for Trusted Dev Setup.
# Sourced by setup.sh — do not execute directly.

# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

fmt_header() {
  echo ""
  echo "== $1 =="
}

fmt_ok() {
  echo "  [ok] $1"
}

fmt_install() {
  echo "  [install] $1"
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
