#!/bin/bash
#
# 1Password CLI setup.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

fmt_header "1Password CLI (op)"

if cmd_exists op; then
  fmt_ok "op already installed ($(op --version))"
else
  fmt_install "1Password CLI"
  case "$OS" in
    macos)
      brew install --cask 1password-cli
      ;;
    ubuntu)
      # Official 1Password CLI installation for Debian/Ubuntu
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --yes --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg 2>/dev/null
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
      sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
      curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null
      sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --yes --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg 2>/dev/null
      sudo apt-get update -qq
      sudo apt-get install -y -qq 1password-cli
      ;;
    arch)
      # 1Password CLI is available via AUR or direct download
      if cmd_exists yay; then
        yay -S --noconfirm 1password-cli
      elif cmd_exists paru; then
        paru -S --noconfirm 1password-cli
      else
        echo "  WARNING: No AUR helper found (yay/paru)."
        echo "  Install 1password-cli manually from AUR."
      fi
      ;;
  esac
fi
