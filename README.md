# Fan Control

Identify and control motherboard fans via hwmon PWM.

> **Disclaimer:** This software is provided as-is without any warranty, express or implied. Use at your own risk. It may modify hardware PWM settings which can affect system cooling and hardware safety.

## Prerequisites
This software depends on `lm-sensors` and hwmon support in the kernel. On Debian/Ubuntu install with:
```bash
sudo apt install lm-sensors
```

## Features
- Auto-discover hwmon driver
- Interactive fan identification wizard
- Systemd service for background control
- Configurable thermal profile

## Install
```bash
sudo bash install.sh
```

Edit `/etc/fan-control/config.conf` with your DRIVER_NAME and TARGET_PWM_INDEX.

Start service:
```bash
sudo systemctl start fan-control.service
sudo systemctl enable fan-control.service
```

## Files
- `scripts/fan_control.sh` - main control loop
- `scripts/identify_fan.sh` - interactive identification
- `config/config.example.conf` - example config
