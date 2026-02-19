#!/bin/bash
#
# git and GitHub CLI setup.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

# ---------------------------------------------------------------------------
# git
# ---------------------------------------------------------------------------

fmt_header "git"

if cmd_exists git; then
  fmt_ok "git already installed ($(git --version))"
else
  fmt_install "git"
  case "$OS" in
    macos)  brew install git ;;
    ubuntu) sudo apt-get install -y -qq git ;;
    arch)   sudo pacman -S --noconfirm --needed git ;;
  esac
fi

# ---------------------------------------------------------------------------
# GitHub CLI (gh)
# ---------------------------------------------------------------------------

fmt_header "GitHub CLI (gh)"

if cmd_exists gh; then
  fmt_ok "gh already installed ($(gh --version | head -1))"
else
  fmt_install "gh"
  case "$OS" in
    macos)
      brew install gh
      ;;
    ubuntu)
      # Official GitHub CLI installation for Debian/Ubuntu
      sudo mkdir -p -m 755 /etc/apt/keyrings
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli-stable.list > /dev/null
      sudo apt-get update -qq
      sudo apt-get install -y -qq gh
      ;;
    arch)
      sudo pacman -S --noconfirm --needed github-cli
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# GitHub Authentication
# ---------------------------------------------------------------------------

fmt_header "GitHub Authentication"

gh_auth_ok=false
gh_scopes_ok=false

if gh auth status > /dev/null 2>&1; then
  gh_auth_ok=true
  # Check for required scopes (read:packages needed for private registries)
  gh_status_output="$(gh auth status 2>&1)"
  if echo "$gh_status_output" | grep -qE 'read:packages|write:packages'; then
    gh_scopes_ok=true
  fi
fi

if $gh_auth_ok && $gh_scopes_ok; then
  fmt_ok "Authenticated with GitHub (with required scopes)"
elif $gh_auth_ok; then
  echo "  GitHub CLI is authenticated but missing required scopes (read:packages, write:packages)."
  echo "  Re-authenticating with required scopes..."
  echo ""
  gh auth login --web --git-protocol https --scopes read:packages,write:packages

  if ! gh auth status > /dev/null 2>&1; then
    echo ""
    echo "ERROR: GitHub re-authentication failed or was cancelled."
    echo "Setup cannot continue without GitHub access."
    exit 1
  fi
  fmt_ok "Authenticated with GitHub (scopes updated)"
else
  echo "  GitHub CLI needs to be authenticated."
  echo "  This will open a browser window for GitHub login."
  echo ""
  gh auth login --web --git-protocol https --scopes read:packages,write:packages

  # Verify authentication succeeded before continuing
  if ! gh auth status > /dev/null 2>&1; then
    echo ""
    echo "ERROR: GitHub authentication failed or was cancelled."
    echo "Setup cannot continue without GitHub access."
    echo "Run this script again and complete the authentication step."
    exit 1
  fi
  fmt_ok "Authenticated with GitHub"
fi
