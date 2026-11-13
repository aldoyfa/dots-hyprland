-- Custom Window Rules for Zoom
-- Fix popups/dropdowns/menus disappearing when moving cursor (XWayland focus issue)
hl.window_rule({
    match = { class = "^(zoom)$", initial_title = "^(menu window)$" },
    stay_focused = true,
})
hl.window_rule({
    match = { class = "^(zoom)$", title = "^(menu window)$" },
    stay_focused = true,
})

-- Float secondary Zoom windows (Breakout rooms, Join dialogs, Chat, Settings, etc.)
hl.window_rule({
    match = { class = "^(zoom)$", title = "^(Breakout rooms.*)$" },
    float = true,
})
hl.window_rule({
    match = { class = "^(zoom)$", title = "^(Join.*)$" },
    float = true,
    stay_focused = true,
})
hl.window_rule({
    match = { class = "^(zoom)$", title = "negative:^(Meeting.*|Zoom Workplace)$" },
    float = true,
})

-- Wuthering Waves Launcher
hl.window_rule({
    match = { class = "^(steam_app_3513350|steam_proton)$", title = "^(Wuthering Waves)$" },
    center = true,
    float = true,
})

