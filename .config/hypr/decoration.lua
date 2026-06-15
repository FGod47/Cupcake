local palette = require("palette")

hl.config({
    general = {
        gaps_in = 6,
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
            enabled = false
        },
        dim_special = 0.3,
        rounding = 10,
        screen_shader = "~/.config/hypr/shaders/rounded_corners.glsl",

        blur = {
            special = true,
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false
        }
    }
})
