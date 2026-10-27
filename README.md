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

## Why this exists
This project came about because I wanted to cool down a Tesla P40 https://link.amazon/B0axQekJj that I got for my home-grown AI lab, and got this Noctua NF-P12 fan https://link.amazon/B0079YdCi which I had to funnel via this Adapter https://link.amazon/B02lmlPL8 and hooked it to my board via the Chassis Fan Connector 2.

*Disclaimer: I may earn a commission via the links above. If you would like to support me I'm very grateful.*

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

## Unnecessary picture

Say hi to the card, the fan and the funnel:

![nvidia Tesla P40](https://lh3.googleusercontent.com/pw/AP1GczPNiXQWa_Plun6T3oJNkD1Gtwr61Y2GEet60nk_oREiro_Sp_dexNlOFibhrzPR6rDdQQNuwXuF9JZjSkscQxomvSEG4OP_eu50irALezhi230NsPmrtB93ejNl7fwJU2137B9N_jONi-Knx8cXnQVPjg=w744-h1323-s-no-gm?authuser=0)
