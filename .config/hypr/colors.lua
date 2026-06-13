local palette = require("palette")

hl.config({
    general = {
        col = {
            active_border = { colors = { palette.primary, palette.secondary }, angle = 45 },
            inactive_border = "rgba(00000000)",
        },
    },
    misc = {
        background_color = palette.background,
    },
})
