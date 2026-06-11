import QtQuick

QtObject {
    // Matugen dynamically generated colors
    readonly property color bg: "{{colors.surface.default.hex}}"
    readonly property color bgAlt: "{{colors.surface_container.default.hex}}"
    readonly property color fg: "{{colors.on_surface.default.hex}}"
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color colorOnPrimary: "{{colors.on_primary.default.hex}}"
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color colorOnSecondary: "{{colors.on_secondary.default.hex}}"
    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color colorOnTertiary: "{{colors.on_tertiary.default.hex}}"
    readonly property color errorColor: "{{colors.error.default.hex}}"
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color surfaceVariant: "{{colors.surface_variant.default.hex}}"
    readonly property color colorOnSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"
    
    // Additional aliases for semantic usage
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color subtext: "{{colors.on_surface_variant.default.hex}}"
    
    // Shared typography
    readonly property string fontName: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 14
}
