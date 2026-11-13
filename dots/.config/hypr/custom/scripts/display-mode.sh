#!/usr/bin/env bash
# Display mode switcher backend (Super+P).
#   display-mode.sh <mirror|extend-right|extend-left|internal|external>
#   display-mode.sh ensure   -> re-enable the laptop panel if no other screen is active
#   display-mode.sh watch    -> run `ensure` whenever a monitor is unplugged
# The chosen layout is persisted to ~/.config/hypr/monitors.lua (sourced by hyprland.lua).

INTERNAL_MODE="1920x1080@165.01"
MONITORS_CONF="$HOME/.config/hypr/monitors.lua"

monitors="$(hyprctl monitors all -j 2>/dev/null)"

internal="$(jq -r '[ .[] | select(.name | test("eDP|LVDS|DSI"; "i")) ][0].name // empty' <<< "$monitors")"
[[ -z "$internal" ]] && internal="eDP-1"
external="$(jq -r --arg i "$internal" '[ .[] | select(.name != $i) ][0].name // empty' <<< "$monitors")"

notify() { notify-send -a "Display" -i video-display "Display mode" "$1"; }

# apply <lua for first monitor> <lua for second monitor>
apply() {
    hyprctl eval "hl.monitor({ $1 })" >/dev/null
    [[ -n "$2" ]] && hyprctl eval "hl.monitor({ $2 })" >/dev/null
    {
        echo "-- Written by ~/.config/hypr/custom/scripts/display-mode.sh (Super+P)"
        echo "hl.monitor({ $1 })"
        [[ -n "$2" ]] && echo "hl.monitor({ $2 })"
    } > "$MONITORS_CONF"
}

int_on="output = '$internal', mode = '$INTERNAL_MODE', scale = 1, disabled = false"

need_external() {
    if [[ -z "$external" ]]; then
        notify "No external display detected"
        exit 1
    fi
}

case "$1" in
    mirror)
        need_external
        apply "$int_on, position = '0x0'" "output = '$external', mode = 'preferred', mirror = '$internal', disabled = false"
        notify "Duplicate"
        ;;
    extend-right)
        need_external
        apply "$int_on, position = '0x0'" "output = '$external', mode = 'preferred', position = 'auto-right', scale = 1, disabled = false"
        notify "Extend, $external on the right"
        ;;
    extend-left)
        need_external
        apply "output = '$external', mode = 'preferred', position = 'auto-left', scale = 1, disabled = false" "$int_on, position = 'auto-right'"
        notify "Extend, $external on the left"
        ;;
    internal)
        if [[ -n "$external" ]]; then
            apply "$int_on, position = '0x0'" "output = '$external', disabled = true"
        else
            apply "$int_on, position = '0x0'"
        fi
        notify "Laptop screen only"
        ;;
    external)
        need_external
        apply "output = '$external', mode = 'preferred', position = '0x0', scale = 1, disabled = false" "output = '$internal', disabled = true"
        notify "External display only"
        ;;
    ensure)
        # Safety net: never leave the session with zero active screens.
        active="$(jq '[ .[] | select(.disabled == false) ] | length' <<< "$monitors")"
        if [[ "$active" == "0" || -z "$external" ]]; then
            int_disabled="$(jq -r --arg i "$internal" '.[] | select(.name == $i) | .disabled' <<< "$monitors")"
            if [[ "$int_disabled" == "true" ]]; then
                apply "$int_on, position = '0x0'"
                notify "External display gone, laptop screen restored"
            fi
        fi
        ;;
    watch)
        sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
        "$0" ensure
        socat -U - "UNIX-CONNECT:$sock" | while read -r line; do
            case "$line" in
                monitorremoved*) sleep 1; "$0" ensure ;;
            esac
        done
        ;;
    *)
        echo "usage: $0 <mirror|extend-right|extend-left|internal|external|ensure|watch>" >&2
        exit 2
        ;;
esac
