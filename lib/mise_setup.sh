#!/bin/bash
#
# mise version manager and Ruby setup.
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
  curl https://mise.run | sh

  # Add mise to PATH for this session
  export PATH="$HOME/.local/bin:$PATH"
fi

# Ensure mise is activated in shell RC files
activate_mise_in_shell() {
  local rc_file="$1"
  # shellcheck disable=SC2016 # Intentionally single-quoted: written literally to RC file
  local activation_line='eval "$(mise activate)"'

  if [ -f "$rc_file" ]; then
    if ! grep -qF "mise activate" "$rc_file"; then
      {
        echo ""
        echo "# mise version manager"
        echo "$activation_line"
      } >> "$rc_file"
      echo "  Added mise activation to $rc_file"
    fi
  fi
}

# Detect which shell RC files exist and activate mise in them
if [ -f "$HOME/.zshrc" ]; then
  activate_mise_in_shell "$HOME/.zshrc"
fi

if [ -f "$HOME/.bashrc" ]; then
  activate_mise_in_shell "$HOME/.bashrc"
fi

# If neither exists, create .bashrc with mise activation (Linux default)
if [ ! -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.bashrc" ]; then
  echo '# mise version manager' > "$HOME/.bashrc"
  # shellcheck disable=SC2016 # Intentionally single-quoted: written literally to RC file
  echo 'eval "$(mise activate)"' >> "$HOME/.bashrc"
  echo "  Created $HOME/.bashrc with mise activation"
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
  fmt_ok "Ruby installed: $(mise exec ruby -- ruby --version)"
fi
