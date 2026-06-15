hl.config({
    decoration = {
        active_opacity = 0.90,
        inactive_opacity = 0.90,
        blur = {
            size = 6,
            passes = 3
        }
    }
})
hl.layer_rule({ match = { namespace = 'quickshell' }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = 'quickshell:.*' }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = 'cupcake-launcher' }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = 'waybar' }, blur = true, ignore_alpha = 0.2 })
hl.window_rule({ match = { class = 'kitty' }, opacity = '1.0 1.0', no_blur = false })
hl.window_rule({ match = { class = 'quickshell' }, opacity = '1.0 1.0', no_blur = false })

