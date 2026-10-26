#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/etc/fan-control/config.conf}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config not found at $CONFIG_FILE"
  exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# --- Dynamic Path Discovery ---
HWMON_DIR=""
for dev in /sys/class/hwmon/hwmon*; do
  [[ ! -d "$dev" ]] && continue
  if [[ -f "$dev/name" ]]; then
    if [[ "$(cat "$dev/name")" == "$DRIVER_NAME" ]]; then
      HWMON_DIR="$dev"
      break
    fi
  fi
done

if [[ -z "$HWMON_DIR" ]]; then
  echo "Error: Could not find hwmon for driver '$DRIVER_NAME'."
  exit 1
fi

PWM_ENABLE="${HWMON_DIR}/pwm${TARGET_PWM_INDEX}_enable"
PWM_VAL="${HWMON_DIR}/pwm${TARGET_PWM_INDEX}"

if [[ ! -f "$PWM_ENABLE" || ! -f "$PWM_VAL" ]]; then
  echo "Error: PWM files not found for index $TARGET_PWM_INDEX in $HWMON_DIR"
  exit 1
fi

cleanup() {
  echo "[!] Stopping fan control service..."
  echo 2 | sudo tee "$PWM_ENABLE" >/dev/null 2>&1 || true
  exit 0
}
trap cleanup SIGINT SIGTERM

# Ensure manual mode
echo 1 | sudo tee "$PWM_ENABLE" >/dev/null

current_mode=-1

log() { echo "[$(date +%T)] $*"; }

log "Starting fan control"
log "Driver: $DRIVER_NAME at $HWMON_DIR, PWM index $TARGET_PWM_INDEX"

while true; do
  GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | tr -d ' ,')
  if [[ ! "$GPU_TEMP" =~ ^[0-9]+$ ]]; then
    log "Warning: could not read GPU temperature"
    sleep "$INTERVAL"
    continue
  fi

  target_mode=-1
  target_pwm=-1

  if [[ "$current_mode" -eq 2 ]]; then
    if (( GPU_TEMP < TEMP_HIGH - HYSTERESIS )); then
      target_mode=1; target_pwm=$PWM_MED
    else
      target_mode=2; target_pwm=$PWM_HIGH
    fi
  elif [[ "$current_mode" -eq 1 ]]; then
    if (( GPU_TEMP >= TEMP_HIGH )); then
      target_mode=2; target_pwm=$PWM_HIGH
    elif (( GPU_TEMP < TEMP_MED - HYSTERESIS )); then
      target_mode=0; target_pwm=$PWM_LOW_VAL
    else
      target_mode=1; target_pwm=$PWM_MED
    fi
  else
    if (( GPU_TEMP >= TEMP_HIGH )); then
      target_mode=2; target_pwm=$PWM_HIGH
    elif (( GPU_TEMP >= TEMP_MED )); then
      target_mode=1; target_pwm=$PWM_MED
    else
      target_mode=0; target_pwm=$PWM_LOW_VAL
    fi
  fi

  if [[ "$target_mode" -ne "$current_mode" ]]; then
    mode_name="LOW"
    [[ "$target_mode" -eq 1 ]] && mode_name="MEDIUM"
    [[ "$target_mode" -eq 2 ]] && mode_name="HIGH"
    log "Temp: ${GPU_TEMP}°C | Mode Change -> $mode_name ($target_pwm PWM)"
    echo "$target_pwm" | sudo tee "$PWM_VAL" >/dev/null
    current_mode=$target_mode
  else
    mode_name="LOW"
    [[ "$current_mode" -eq 1 ]] && mode_name="MEDIUM"
    [[ "$current_mode" -eq 2 ]] && mode_name="HIGH"
    log "Temp: ${GPU_TEMP}°C | Mode: $mode_name"
  fi

  sleep "$INTERVAL"
done
