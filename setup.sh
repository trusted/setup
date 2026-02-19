#!/bin/bash
#
# Trusted Dev Setup
#
# Bootstraps a developer machine with the baseline tools required to clone
# and run any Trusted project's bin/setup script.
#
# Usage:
#   # First-time setup or update
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/devsetup/main/setup.sh)"
#
#   # Re-run a specific migration
#   ./setup.sh --rerun <timestamp>

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve script directory (works for both local execution and curl pipe)
# ---------------------------------------------------------------------------

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Running via curl | bash — clone (or update) the repo at ~/Work/devsetup
  DEVSETUP_CLONE_DIR="$HOME/Work/devsetup"
  DEVSETUP_REPO="${DEVSETUP_REPO:-trusted/devsetup}"
  DEVSETUP_REF="${DEVSETUP_REF:-main}"

  if [ -d "$DEVSETUP_CLONE_DIR/.git" ]; then
    # Abort if there are uncommitted changes
    if ! git -C "$DEVSETUP_CLONE_DIR" diff --quiet HEAD 2>/dev/null; then
      echo "ERROR: $DEVSETUP_CLONE_DIR has uncommitted changes."
      echo "Commit or stash them, then re-run setup."
      exit 1
    fi

    # Abort if on the wrong branch
    local_branch="$(git -C "$DEVSETUP_CLONE_DIR" branch --show-current)"
    if [ "$local_branch" != "$DEVSETUP_REF" ]; then
      echo "ERROR: $DEVSETUP_CLONE_DIR is on branch '$local_branch', expected '$DEVSETUP_REF'."
      echo "Switch to $DEVSETUP_REF, then re-run setup."
      exit 1
    fi

    echo "Updating devsetup from github.com/$DEVSETUP_REPO ($DEVSETUP_REF)..."
    git -C "$DEVSETUP_CLONE_DIR" pull --ff-only --quiet
  else
    echo "Cloning devsetup from github.com/$DEVSETUP_REPO ($DEVSETUP_REF)..."
    mkdir -p "$HOME/Work"
    git clone "https://github.com/$DEVSETUP_REPO.git" "$DEVSETUP_CLONE_DIR" --quiet
    git -C "$DEVSETUP_CLONE_DIR" checkout "$DEVSETUP_REF" --quiet
  fi

  SCRIPT_DIR="$DEVSETUP_CLONE_DIR"
fi

# ---------------------------------------------------------------------------
# Load libraries
# ---------------------------------------------------------------------------

# shellcheck source=lib/migrate.sh
source "$SCRIPT_DIR/lib/migrate.sh"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

ACTION="setup"
RERUN_TIMESTAMP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rerun)
      ACTION="rerun"
      RERUN_TIMESTAMP="${2:-}"
      if [ -z "$RERUN_TIMESTAMP" ]; then
        echo "ERROR: --rerun requires a migration timestamp."
        echo "Usage: setup.sh --rerun <timestamp>"
        exit 1
      fi
      shift 2
      ;;
    --help|-h)
      echo "Trusted Dev Setup"
      echo ""
      echo "Usage: setup.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --rerun <timestamp>    Re-run a specific migration"
      echo "  --help                 Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run setup.sh --help for usage."
      exit 1
      ;;
  esac
done

# Handle --rerun before anything else
if [ "$ACTION" = "rerun" ]; then
  rerun_migration "$SCRIPT_DIR" "$RERUN_TIMESTAMP"
  exit $?
fi

# ---------------------------------------------------------------------------
# Helpers
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

echo ""
echo "= Trusted Dev Setup ="
echo ""
echo "  Platform: $OS"
echo ""

# ---------------------------------------------------------------------------
# Package manager
# ---------------------------------------------------------------------------

fmt_header "Package Manager"

case "$OS" in
  macos)
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

# Ensure gh is authenticated
fmt_header "GitHub Authentication"

if gh auth status > /dev/null 2>&1; then
  fmt_ok "Already authenticated with GitHub"
elif [ "${CI:-}" = "true" ]; then
  echo "  Skipping interactive GitHub auth (CI environment detected)."
  echo "  Set GH_TOKEN to authenticate gh in CI."
else
  echo "  GitHub CLI needs to be authenticated."
  echo "  This will open a browser window for GitHub login."
  echo ""
  gh auth login --web --git-protocol https
fi

# ---------------------------------------------------------------------------
# mise (version manager)
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

# ---------------------------------------------------------------------------
# 1Password CLI (op)
# ---------------------------------------------------------------------------

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
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg 2>/dev/null
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
      sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
      curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null
      sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg 2>/dev/null
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

# ---------------------------------------------------------------------------
# Build essentials (needed for compiling native Ruby gems, etc.)
# ---------------------------------------------------------------------------

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
    ;;
  ubuntu)
    if dpkg -l build-essential > /dev/null 2>&1; then
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

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

fmt_header "Docker"

if cmd_exists docker; then
  fmt_ok "Docker already installed ($(docker --version))"
else
  fmt_install "Docker"
  case "$OS" in
    macos)
      brew install docker
      ;;
    ubuntu)
      # Official Docker Engine installation for Ubuntu
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /tmp/docker.asc
      sudo mv /tmp/docker.asc /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc
      # shellcheck disable=SC1091
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update -qq
      sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      ;;
    arch)
      sudo pacman -S --noconfirm --needed docker
      sudo systemctl enable docker.service
      sudo usermod -aG docker "$USER" 2>/dev/null || true
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Docker Compose
# ---------------------------------------------------------------------------

fmt_header "Docker Compose"

if docker compose version > /dev/null 2>&1; then
  fmt_ok "Docker Compose already installed ($(docker compose version --short))"
else
  fmt_install "Docker Compose"
  case "$OS" in
    macos)
      brew install docker-compose
      # Link compose plugin so `docker compose` works
      mkdir -p "$HOME/.docker/cli-plugins"
      if [ -f "$(brew --prefix)/opt/docker-compose/bin/docker-compose" ]; then
        ln -sfn "$(brew --prefix)/opt/docker-compose/bin/docker-compose" "$HOME/.docker/cli-plugins/docker-compose"
      fi
      ;;
    ubuntu)
      sudo apt-get install -y -qq docker-compose-plugin
      ;;
    arch)
      sudo pacman -S --noconfirm --needed docker-compose
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Colima (macOS only — container runtime)
# ---------------------------------------------------------------------------

if [ "$OS" = "macos" ]; then
  fmt_header "Colima"

  if cmd_exists colima; then
    fmt_ok "Colima already installed ($(colima version | head -1))"
  else
    fmt_install "Colima"
    brew install colima
  fi
fi

# ---------------------------------------------------------------------------
# AWS CLI
# ---------------------------------------------------------------------------

fmt_header "AWS CLI"

if cmd_exists aws; then
  fmt_ok "AWS CLI already installed ($(aws --version 2>&1))"
else
  fmt_install "AWS CLI"
  case "$OS" in
    macos)
      brew install awscli
      ;;
    ubuntu)
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
      unzip -qo /tmp/awscliv2.zip -d /tmp/aws-install
      sudo /tmp/aws-install/aws/install
      rm -rf /tmp/awscliv2.zip /tmp/aws-install
      ;;
    arch)
      if cmd_exists yay; then
        yay -S --noconfirm aws-cli-v2
      elif cmd_exists paru; then
        paru -S --noconfirm aws-cli-v2
      else
        echo "  WARNING: No AUR helper found (yay/paru)."
        echo "  Install aws-cli-v2 manually from AUR."
      fi
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# AWS VPN Client
# ---------------------------------------------------------------------------

fmt_header "AWS VPN Client"

case "$OS" in
  macos)
    if [ -d "/Applications/AWS VPN Client" ] || [ -d "/Applications/AWS VPN Client.app" ]; then
      fmt_ok "AWS VPN Client already installed"
    else
      fmt_install "AWS VPN Client"
      brew install --cask aws-vpn-client
    fi
    ;;
  ubuntu)
    if cmd_exists awsvpnclient; then
      fmt_ok "AWS VPN Client already installed"
    else
      fmt_install "AWS VPN Client"
      curl -fsSL "https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb" -o /tmp/awsvpnclient.deb
      sudo apt-get install -y -qq /tmp/awsvpnclient.deb
      rm -f /tmp/awsvpnclient.deb
    fi
    ;;
  arch)
    if cmd_exists awsvpnclient; then
      fmt_ok "AWS VPN Client already installed"
    else
      fmt_install "AWS VPN Client"
      if cmd_exists yay; then
        yay -S --noconfirm awsvpnclient
      elif cmd_exists paru; then
        paru -S --noconfirm awsvpnclient
      else
        echo "  WARNING: No AUR helper found (yay/paru)."
        echo "  Install awsvpnclient manually from AUR."
      fi
    fi
    ;;
esac

# ---------------------------------------------------------------------------
# Migrations
# ---------------------------------------------------------------------------

fmt_header "Migrations"

run_migrations "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# Work directory
# ---------------------------------------------------------------------------

WORK_DIR="$HOME/Work"

fmt_header "Work Directory"

mkdir -p "$WORK_DIR"
fmt_ok "$WORK_DIR ready"

clone_to_work() {
  local repo="$1"
  local name="$2"
  local dir="$WORK_DIR/$name"

  if [ -d "$dir/.git" ]; then
    fmt_ok "$name already at $dir"
  elif gh auth status > /dev/null 2>&1; then
    fmt_install "Cloning $name to $dir"
    gh repo clone "$repo" "$dir" -- --quiet
  fi
}

clone_to_work "trusted/docs" "docs"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "= Trusted Dev Setup Complete ="
echo ""
echo "Next steps:"
echo "  1. Open a new terminal (or run: source ~/.zshrc)"
echo "  2. Clone a project:  cd ~/Work && gh repo clone trusted/<repo-name>"
echo "  3. Run project setup: cd <repo-name> && bin/setup"
echo ""
