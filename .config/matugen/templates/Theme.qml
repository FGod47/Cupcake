pragma Singleton
import QtQuick

QtObject {
    property color colBackground: "{{colors.background.default.hex}}"
    property color colOnBackground: "{{colors.on_background.default.hex}}"
    property color colSurface: "{{colors.surface.default.hex}}"
    property color colSurfaceContainer: "{{colors.surface_container.default.hex}}"
    property color colSurfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    property color colOnSurface: "{{colors.on_surface.default.hex}}"
    property color colOnSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"
    property color colOutline: "{{colors.outline.default.hex}}"
    property color colPrimary: "{{colors.primary.default.hex}}"
    property color colOnPrimary: "{{colors.on_primary.default.hex}}"
    property color colSecondary: "{{colors.secondary.default.hex}}"
    property color colError: "{{colors.error.default.hex}}"
}
