#!/bin/bash
#
# Build essentials setup.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

fmt_header "Build Essentials"

case "$OS" in
  macos)
    # Xcode Command Line Tools are required for native compilation
    if xcode-select -p > /dev/null 2>&1; then
      fmt_ok "Xcode Command Line Tools already installed"
    else
      fmt_install "Xcode Command Line Tools"
      xcode-select --install 2>/dev/null || true
      echo "  NOTE: A dialog may have opened. Complete the installation and re-run this script."
    fi

    # libyaml is required for building Ruby from source
    if brew list libyaml > /dev/null 2>&1; then
      fmt_ok "libyaml already installed"
    else
      fmt_install "libyaml"
      brew install libyaml
    fi
    ;;
  ubuntu)
    if dpkg -s build-essential > /dev/null 2>&1; then
      fmt_ok "build-essential already installed"
    else
      fmt_install "build-essential"
      sudo apt-get install -y -qq build-essential libssl-dev libreadline-dev zlib1g-dev libyaml-dev
    fi
    ;;
  arch)
    if pacman -Qi base-devel > /dev/null 2>&1; then
      fmt_ok "base-devel already installed"
    else
      fmt_install "base-devel"
      sudo pacman -S --noconfirm --needed base-devel
    fi

    ;;
esac
