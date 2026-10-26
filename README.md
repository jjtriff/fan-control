# Fan Control

Identify and control motherboard fans via hwmon PWM.

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
