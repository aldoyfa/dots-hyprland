hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit user keybinds" })

--##! Shell
-- end4-pC settings panel (an overlay, so Super+Q won't close it: use this bind or Escape)
hl.bind("SUPER + Escape", hl.dsp.global("quickshell:settingsToggle"), { description = "Shell: Toggle settings" })

-- Super tap opens search. Hyprland's own release bind is used instead of the shell's
-- searchToggleRelease, because Hyprland cancels it when another key was pressed while holding Super.
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")
hl.bind("SUPER_L", hl.dsp.exec_cmd("qs -c $qsConfig ipc call search toggle || pkill fuzzel || fuzzel"), { release = true })
hl.bind("SUPER_R", hl.dsp.exec_cmd("qs -c $qsConfig ipc call search toggle || pkill fuzzel || fuzzel"), { release = true })

--##! Display
-- Super+P: display mode switcher (laptop / duplicate / extend / external). Press again to step through.
hl.unbind("SUPER + P")
hl.bind("SUPER + P", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/monitor-menu.sh"),
    { description = "Display: Mode switcher (duplicate / extend / single)" })
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/monitor-menu.sh"))

--##! Window
-- Pin moved here since Super+P is the display switcher
hl.bind("SUPER + ALT + P", hl.dsp.window.pin(), { description = "Window: Pin" })

--##! Utilities
hl.bind("SUPER + Space", hl.dsp.exec_cmd("pidof slurp || ~/.local/bin/jp-romaji"),
    { description = "Utilities: Japanese OCR to romaji overlay" })

-- AI features are disabled: drop the default "AI summary of selected text" bind
hl.unbind("SUPER + SHIFT + ALT + mouse:273")
