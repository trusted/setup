#!/bin/bash
#
# Package manager bootstrap.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

fmt_header "Package Manager"

case "$OS" in
  macos)
    # Activate Homebrew for this session if it exists but isn't on PATH yet.
    # This covers re-runs in the same terminal before the shell RC is sourced.
    if ! cmd_exists brew; then
      if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi

    if cmd_exists brew; then
      fmt_ok "Homebrew already installed"
    else
      fmt_install "Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      # Add Homebrew to PATH for this session
      if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    ;;
  ubuntu)
    fmt_install "Updating apt package index"
    sudo apt-get update -qq
    fmt_ok "apt updated"
    ;;
  arch)
    fmt_install "Updating pacman package database"
    sudo pacman -Syu --noconfirm
    fmt_ok "pacman updated"
    ;;
esac
