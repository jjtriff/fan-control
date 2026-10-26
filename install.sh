#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/opt/fan-control"
CONFIG_DIR="/etc/fan-control"
SERVICE_NAME="fan-control.service"

echo "Installing Fan Control..."

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo"
  exit 1
fi

mkdir -p "$INSTALL_DIR"/{scripts,config}
mkdir -p "$CONFIG_DIR"

cp scripts/fan_control.sh "$INSTALL_DIR/scripts/"
cp scripts/identify_fan.sh "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/scripts/"*.sh

if [[ ! -f "$CONFIG_DIR/config.conf" ]]; then
  cp config/config.example.conf "$CONFIG_DIR/config.conf"
  echo "Created config at $CONFIG_DIR/config.conf"
  echo "Edit it to match your hardware."
else
  echo "Config already exists, skipping."
fi

# Interactive identification
read -rp "Run fan identification wizard now? [y/N] " ans
if [[ "$ans" =~ ^[Yy] ]]; then
  bash "$INSTALL_DIR/scripts/identify_fan.sh"
  echo "If identification succeeded, update $CONFIG_DIR/config.conf with the printed values."
fi

# Install systemd service
cp systemd/fan-control.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable fan-control.service
echo "Service installed and enabled. Start with: systemctl start fan-control.service"

echo "Installation complete."
