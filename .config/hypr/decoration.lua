local HOME = os.getenv("HOME") or "/home/zero"
local palette = require("palette")

hl.config({
    general = {
        gaps_in = 7,
        gaps_out = 10,
        border_size = 0,
        col = {
            active_border = { colors = { palette.primary, palette.secondary }, angle = 45 },
            inactive_border = "rgba(00000000)",
        },
        resize_on_border = true,
        layout = "dwindle"
    },

    decoration = {
        shadow = {
            enabled = false,
            range = 4,
        },
        dim_special = 0.3,
        rounding = 10,
        screen_shader = HOME .. "/.config/hypr/shaders/rounded_corners.glsl",

        blur = {
            enabled = true,
            xray = false,
            special = false,
            new_optimizations = true,
            size = 10,
            passes = 3,
            popups = false,
            ignore_opacity = true,
        }
    }
})
