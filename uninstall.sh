#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="fan-control.service"
INSTALL_DIR="/opt/fan-control"
CONFIG_DIR="/etc/fan-control"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo"
  exit 1
fi

systemctl stop fan-control.service || true
systemctl disable fan-control.service || true
rm -f /etc/systemd/system/fan-control.service
systemctl daemon-reload

read -rp "Remove config directory $CONFIG_DIR? [y/N] " ans
if [[ "$ans" =~ ^[Yy] ]]; then
  rm -rf "$CONFIG_DIR"
fi

read -rp "Remove install directory $INSTALL_DIR? [y/N] " ans2
if [[ "$ans2" =~ ^[Yy] ]]; then
  rm -rf "$INSTALL_DIR"
fi

echo "Uninstall complete."
