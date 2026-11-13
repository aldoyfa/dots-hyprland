#!/usr/bin/env bash
# Super+P: open the display switcher, or step to the next mode if it is already open.
qs -c display-switcher ipc call displaySwitcher next 2>/dev/null && exit 0
exec qs -c display-switcher
