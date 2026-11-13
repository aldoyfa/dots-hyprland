#!/usr/bin/env bash

monitors="$(hyprctl monitors -j)"

internal="$(jq -r '
  [ .[] | select(.name | test("eDP|LVDS|DSI"; "i")) ][0].name // empty
' <<< "$monitors")"

external="$(jq -r --arg internal "$internal" '
  [ .[] | select(.name != $internal) ][0].name // empty
' <<< "$monitors")"

if [[ -z "$internal" || -z "$external" ]]; then
    notify-send "Monitor" "Monitor eksternal tidak terdeteksi"
    exit 1
fi

external_x="$(jq -r --arg name "$external" '
  .[] | select(.name == $name) | .x
' <<< "$monitors")"

if (( external_x < 0 )); then
    hyprctl eval "hl.monitor({output='$internal', mode='preferred', position='0x0', scale=1})"
    hyprctl eval "hl.monitor({output='$external', mode='preferred', position='auto-right', scale=1})"
    notify-send "Monitor" "Monitor eksternal dipindahkan ke kanan"
else
    hyprctl eval "hl.monitor({output='$external', mode='preferred', position='auto-left', scale=1})"
    hyprctl eval "hl.monitor({output='$internal', mode='preferred', position='auto-right', scale=1})"
    notify-send "Monitor" "Monitor eksternal dipindahkan ke kiri"
fi
