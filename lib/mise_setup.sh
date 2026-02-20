#!/bin/bash
#
# mise version manager, Ruby, Node.js, and Yarn setup.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

# ---------------------------------------------------------------------------
# mise
# ---------------------------------------------------------------------------

fmt_header "mise"

if cmd_exists mise; then
  fmt_ok "mise already installed ($(mise --version))"
else
  fmt_install "mise"

  case "$OS" in
    macos)
      brew install mise
      ;;
    ubuntu)
      sudo install -dm 755 /etc/apt/keyrings
      curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc 1> /dev/null
      echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
      sudo apt-get update -qq
      sudo apt-get install -y -qq mise
      ;;
    arch)
      echo "  ERROR: mise is expected to be pre-installed on Arch/Omarchy but was not found."
      exit 1
      ;;
  esac
fi

# Ensure mise is activated in ~/.zshrc
if [ ! -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
fi

if ! grep -qF "mise activate" "$HOME/.zshrc" 2>/dev/null; then
  {
    echo ""
    echo "# mise version manager"
    # shellcheck disable=SC2016 # Intentionally single-quoted: written literally to RC file
    echo 'eval "$(mise activate)"'
  } >> "$HOME/.zshrc"
  echo "  Added mise activation to ~/.zshrc"
fi

# Activate mise for this session
eval "$(mise activate bash)" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Ruby (via mise — global default for running bin/setup scripts)
# ---------------------------------------------------------------------------

fmt_header "Ruby (via mise)"

if mise which ruby > /dev/null 2>&1; then
  fmt_ok "Ruby already available via mise"
else
  fmt_install "Ruby (latest stable via mise)"
  mise use --global ruby@latest
  fmt_ok "Ruby installed: $(mise exec -- ruby --version)"
fi

# ---------------------------------------------------------------------------
# Node.js (via mise — global default for running bin/setup scripts)
# ---------------------------------------------------------------------------

fmt_header "Node.js (via mise)"

# Always ensure the global default is LTS. A previous run or manual config
# may have set it to "latest" (e.g. v25+), which drops corepack and breaks
# yarn. This is idempotent — mise is a no-op if already set to lts.
fmt_install "Ensuring Node.js global default is LTS"
mise use --global node@lts
fmt_ok "Node.js LTS active: $(mise exec -- node --version)"

# ---------------------------------------------------------------------------
# Yarn (via corepack — ships with Node.js LTS)
# ---------------------------------------------------------------------------

fmt_header "Yarn (via corepack)"

if cmd_exists yarn; then
  fmt_ok "yarn already available ($(yarn --version 2>/dev/null))"
else
  fmt_install "Enabling corepack for yarn"
  mise exec -- corepack enable

  # corepack installs shims to the Node prefix bin directory, which may not
  # be on PATH yet. Reshim mise so the yarn shim is available.
  mise reshim 2>/dev/null || true

  if cmd_exists yarn; then
    fmt_ok "yarn enabled via corepack"
  else
    echo "  WARNING: yarn was enabled via corepack but is not yet on PATH."
    echo "  It will be available after restarting your shell."
  fi
fi
