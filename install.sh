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
  tmp=$(mktemp)
  bash "$INSTALL_DIR/scripts/identify_fan.sh" 2>&1 | tee "$tmp"
  output=$(cat "$tmp")
  rm -f "$tmp"
  driver_line=$(echo "$output" | grep '^DRIVER_NAME=')
  pwm_line=$(echo "$output" | grep '^TARGET_PWM_INDEX=')
  if [[ -n "$driver_line" && -n "$pwm_line" ]]; then
    read -rp "Write $driver_line and $pwm_line to $CONFIG_DIR/config.conf? [y/N] " save_ans
    if [[ "$save_ans" =~ ^[Yy] ]]; then
      cfg="$CONFIG_DIR/config.conf"
      # Ensure config exists
      [[ -f "$cfg" ]] || cp config/config.example.conf "$cfg"
      # Extract values
      DRIVER_VAL=$(echo "$driver_line" | cut -d= -f2- | tr -d '"')
      PWM_VAL=$(echo "$pwm_line" | cut -d= -f2-)
      sed -i "s/^DRIVER_NAME=.*/DRIVER_NAME=\"$DRIVER_VAL\"/" "$cfg"
      sed -i "s/^TARGET_PWM_INDEX=.*/TARGET_PWM_INDEX=$PWM_VAL/" "$cfg"
      echo "Updated $cfg with identified values."
    fi
  else
    echo "Identification did not produce DRIVER_NAME/TARGET_PWM_INDEX, skipping config update."
  fi
fi

# Install systemd service
cp systemd/fan-control.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable fan-control.service
echo "Service installed and enabled. Start with: systemctl start fan-control.service"

echo "Installation complete."
