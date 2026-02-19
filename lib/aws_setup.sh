#!/bin/bash
#
# AWS CLI and AWS VPN Client setup.
# Sourced by setup.sh — do not execute directly.
# Requires: lib/common.sh

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
      # Ensure unzip is available (not always present on minimal Ubuntu installs)
      if ! cmd_exists unzip; then
        sudo apt-get install -y -qq unzip
      fi
      aws_arch="x86_64"
      if [ "$(uname -m)" = "aarch64" ]; then
        aws_arch="aarch64"
      fi
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o /tmp/awscliv2.zip
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
    # AWS VPN Client is a GUI app installed to /opt/awsvpnclient (no PATH binary)
    if [ -d "/opt/awsvpnclient" ]; then
      fmt_ok "AWS VPN Client already installed"
    else
      fmt_install "AWS VPN Client"
      vpn_arch="$(dpkg --print-architecture)"
      curl -fsSL "https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_${vpn_arch}.deb" -o /tmp/awsvpnclient.deb
      sudo apt-get install -y -qq /tmp/awsvpnclient.deb
      rm -f /tmp/awsvpnclient.deb
    fi
    ;;
  arch)
    if [ -d "/opt/awsvpnclient" ]; then
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
