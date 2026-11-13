hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@165.01",
    position = "0x0",
    scale = 1,
})

-- External monitor (HDMI-A-1) is dynamically managed by monitor-menu.sh

hl.config({
    misc = {
        vrr = 1,
    },
})
