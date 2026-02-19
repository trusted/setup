#!/bin/bash
#
# Doctor check: Package manager.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

fmt_header "Package Manager"

case "$OS" in
  macos)
    check_cmd "Homebrew" "brew"
    ;;
  ubuntu)
    check_cmd "apt-get" "apt-get"
    ;;
  arch)
    check_cmd "pacman" "pacman"
    ;;
esac
