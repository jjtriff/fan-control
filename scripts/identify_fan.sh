#!/usr/bin/env bash
set -euo pipefail

echo "=== Fan Identifier ==="
echo "Listing hwmon devices:"
mapfile -t devs < <(find /sys/class/hwmon -maxdepth 1 -type l -name 'hwmon*' | sort)
declare -A names
for i in "${!devs[@]}"; do
  d="${devs[$i]}"
  if [[ -f "$d/name" ]]; then
    name=$(cat "$d/name")
    names["$d"]="$name"
    echo "  [$i] $d -> $name"
  fi
done

if [[ ${#devs[@]} -eq 0 ]]; then
  echo "No hwmon devices found. Ensure hwmon is enabled in kernel."
  exit 1
fi

echo
read -rp "Enter hwmon path (e.g., /sys/class/hwmon/hwmon3) or number [0-$((${#devs[@]}-1))]: " sel
if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >=0 && sel < ${#devs[@]} )); then
  HWMON="${devs[$sel]}"
elif [[ -d "$sel" ]]; then
  HWMON="$sel"
else
  echo "Invalid selection"
  exit 1
fi

DRIVER=$(cat "$HWMON/name")
echo "Selected: $HWMON ($DRIVER)"

# Find PWM indices
pwms=()
for i in {1..10}; do
  if [[ -f "$HWMON/pwm${i}_enable" && -f "$HWMON/pwm${i}" ]]; then
    pwms+=($i)
  fi
done

if [[ ${#pwms[@]} -eq 0 ]]; then
  echo "No PWM channels found in $HWMON"
  exit 1
fi

echo "Found PWM channels: ${pwms[*]}"
echo
for i in "${pwms[@]}"; do
  enable_file="$HWMON/pwm${i}_enable"
  pwm_file="$HWMON/pwm${i}"
  old_en=$(cat "$enable_file")
  old_pwm=$(cat "$pwm_file")
  echo "Testing PWM $i (current mode $old_en, value $old_pwm)"
  echo 1 | sudo tee "$enable_file" >/dev/null
  echo 255 | sudo tee "$pwm_file" >/dev/null
  read -rp "Is this fan? [y/N] " ans
  # Restore
  echo "$old_en" | sudo tee "$enable_file" >/dev/null
  if [[ "$old_en" -eq 1 ]]; then
    echo "$old_pwm" | sudo tee "$pwm_file" >/dev/null
  fi
  if [[ "$ans" =~ ^[Yy] ]]; then
    echo "Selected PWM $i as target"
    echo "DRIVER_NAME=$DRIVER"
    echo "TARGET_PWM_INDEX=$i"
    exit 0
  fi
done

echo "No fan selected."
