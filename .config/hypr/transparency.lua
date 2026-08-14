hl.config({
    decoration = {
        active_opacity = 0.20,
        inactive_opacity = 0.20,
        blur = {
            enabled = true,
            size = 3,
            passes = 3,
            xray = true,
            popups = false,
            ignore_opacity = true
        }
    }
})
hl.layer_rule({ match = { namespace = 'quickshell' }, blur = true })
hl.layer_rule({ match = { namespace = 'quickshell' }, ignore_alpha = .30 })
hl.layer_rule({ match = { namespace = 'quickshell' }, xray = true })

hl.layer_rule({ match = { namespace = 'quickshell:.*' }, blur = true })
hl.layer_rule({ match = { namespace = 'quickshell:.*' }, ignore_alpha = .30 })
hl.layer_rule({ match = { namespace = 'quickshell:.*' }, xray = true })
hl.layer_rule({ match = { namespace = 'quickshell:.*' }, blur_popups = true })

hl.layer_rule({ match = { namespace = 'cupcake-launcher' }, blur = true })
hl.layer_rule({ match = { namespace = 'cupcake-launcher' }, ignore_alpha = .30 })
hl.layer_rule({ match = { namespace = 'cupcake-launcher' }, xray = true })

hl.layer_rule({ match = { namespace = 'cupcake-wallpaper' }, blur = true })
hl.layer_rule({ match = { namespace = 'cupcake-wallpaper' }, ignore_alpha = .30 })
hl.layer_rule({ match = { namespace = 'cupcake-wallpaper' }, xray = true })

hl.layer_rule({ match = { namespace = 'cupcake-settings' }, blur = true })
hl.layer_rule({ match = { namespace = 'cupcake-settings' }, ignore_alpha = .30 })
hl.layer_rule({ match = { namespace = 'cupcake-settings' }, xray = true })

hl.window_rule({ match = { class = 'quickshell' }, opacity = '1.0 1.0' })
hl.window_rule({ match = { class = 'quickshell' }, no_blur = false })
