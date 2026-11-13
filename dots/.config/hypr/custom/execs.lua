hl.on("hyprland.start", function()
    -- Display switcher safety net: if the external display is unplugged while the laptop
    -- panel is disabled ("External only"), bring the laptop panel back.
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/display-mode.sh watch")
end)
