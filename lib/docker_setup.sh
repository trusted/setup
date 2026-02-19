#!/bin/bash
#
# Docker, Docker Compose, and Colima setup.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

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
