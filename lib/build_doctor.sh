#!/bin/bash
#
# Doctor check: Build essentials.
# Sourced by doctor.sh — do not execute directly.
# Requires: lib/common.sh, doctor helpers (check_pass, check_fail, check_cmd)

fmt_header "Build Essentials"

check_cmd "make" "make"

if cmd_exists gcc; then
  check_pass "gcc is installed"
elif cmd_exists cc; then
  check_pass "cc is installed"
else
  check_fail "Neither gcc nor cc is installed"
fi

case "$OS" in
  macos)
    if xcode-select -p > /dev/null 2>&1; then
      check_pass "Xcode Command Line Tools are installed"
    else
      check_fail "Xcode Command Line Tools are not installed"
    fi
    ;;
  ubuntu)
    if dpkg -s build-essential > /dev/null 2>&1; then
      check_pass "build-essential is installed"
    else
      check_fail "build-essential is not installed"
    fi
    ;;
  arch)
    if pacman -Qi base-devel > /dev/null 2>&1; then
      check_pass "base-devel is installed"
    else
      check_fail "base-devel is not installed"
    fi
    ;;
esac
