hl.config({
    decoration = {
        active_opacity = 0.90,
        inactive_opacity = 0.90
    }
})
hl.layer_rule({ match = { namespace = 'quickshell' }, blur = true, ignore_alpha = 0.001, xray = true })
hl.layer_rule({ match = { namespace = 'quickshell:.*' }, blur_popups = true, blur = true, ignore_alpha = 0.001, xray = true })
hl.layer_rule({ match = { namespace = 'cupcake-launcher' }, blur = true, ignore_alpha = 0.001, xray = true })
hl.layer_rule({ match = { namespace = 'cupcake-wallpaper' }, blur = true, ignore_alpha = 0.001, xray = true })
hl.window_rule({ match = { class = 'quickshell' }, opacity = '1.0 1.0', no_blur = false })
