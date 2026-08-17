pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: themeSingleton

    readonly property string homeDir: Quickshell.env("HOME")

    property bool globalTransparency: true
    
    property bool isDark: Quickshell.env("CUPCAKE_IS_DARK") === "light" ? false : true
    
    Process {
        id: initThemeConfigs
        command: ["bash", "-c", "cat ~/.config/cupcake/.color_mode 2>/dev/null; echo '---'; cat ~/.config/cupcake/.transparency 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_transparency 2>/dev/null; echo '---'; cat ~/.config/cupcake/.font_default 2>/dev/null; echo '---'; cat ~/.config/cupcake/.font_mono 2>/dev/null; echo '---'; cat ~/.config/cupcake/.font_default_scale 2>/dev/null; echo '---'; cat ~/.config/cupcake/.font_mono_scale 2>/dev/null; echo '---'; cat ~/.config/cupcake/.font_size 2>/dev/null; echo '---'; cat ~/.config/cupcake/.font_weight 2>/dev/null; echo '---'; cat ~/.config/cupcake/.app_font_default 2>/dev/null; echo '---'; cat ~/.config/cupcake/.app_font_mono 2>/dev/null; echo '---'; cat ~/.config/cupcake/.app_font_mono_scale 2>/dev/null; echo '---'; cat ~/.config/cupcake/.app_font_size 2>/dev/null; echo '---'; cat ~/.config/cupcake/.app_font_weight 2>/dev/null; echo '---'; cat ~/.config/cupcake/.slider_thickness 2>/dev/null; echo '---'; cat ~/.config/cupcake/.show_slider_thumb 2>/dev/null; echo '---'; cat ~/.config/cupcake/.liquidify 2>/dev/null; echo '---'; cat ~/.config/cupcake/.show_card_background 2>/dev/null; echo '---'; cat ~/.config/cupcake/.applauncher_style 2>/dev/null; echo '---'; cat ~/.config/cupcake/.wallpaper_switcher_style 2>/dev/null; echo '---'; cat ~/.config/cupcake/.show_dividers 2>/dev/null; echo '---'; cat ~/.config/cupcake/.row_spacing 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_dropdown_style 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_position 2>/dev/null; echo '---'; cat ~/.config/cupcake/.bar_opacity 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return;
                let p = text.trim().split('---');
                if (p[0] && p[0].trim() !== "") themeSingleton.isDark = (p[0].trim() !== "light");
                if (p[1] && p[1].trim() === "false") themeSingleton.globalTransparency = false;
                if (p[2]) {
                    let bt = (p[2].trim() !== "false");
                    themeSingleton.quickshellTransparency = bt;
                    themeSingleton.barTransparency = bt;
                }
                if (p[3] && p[3].trim() !== "") themeSingleton.defaultFontFamily = p[3].trim();
                if (p[4] && p[4].trim() !== "") themeSingleton.monoFontFamily = p[4].trim();
                if (p[5]) { let v = parseFloat(p[5].trim()); if (!isNaN(v)) themeSingleton.defaultFontScale = v; }
                if (p[6]) { let v = parseFloat(p[6].trim()); if (!isNaN(v)) themeSingleton.monoFontScale = v; }
                if (p[7]) { let v = parseInt(p[7].trim()); if (!isNaN(v)) themeSingleton.defaultFontSize = v; }
                if (p[8]) { let v = parseInt(p[8].trim()); if (!isNaN(v)) themeSingleton.defaultFontWeight = v; }
                if (p[9] && p[9].trim() !== "") themeSingleton.appFontFamily = p[9].trim();
                if (p[10] && p[10].trim() !== "") themeSingleton.appMonoFamily = p[10].trim();
                if (p[11]) { let v = parseFloat(p[11].trim()); if (!isNaN(v)) themeSingleton.appMonoScale = v; }
                if (p[12]) { let v = parseInt(p[12].trim()); if (!isNaN(v)) themeSingleton.appFontSize = v; }
                if (p[13]) { let v = parseInt(p[13].trim()); if (!isNaN(v)) themeSingleton.appFontWeight = v; }
                if (p[14]) { let v = parseFloat(p[14].trim()); if (!isNaN(v)) themeSingleton.sliderThickness = v; }
                if (p[15] && p[15].trim() === "false") themeSingleton.showSliderThumb = false;
                if (p[16] && p[16].trim() === "false") themeSingleton.liquidify = false;
                if (p[17] && p[17].trim() === "false") themeSingleton.showCardBackground = false;
                if (p[18] && p[18].trim() !== "") themeSingleton.appLauncherStyle = p[18].trim();
                if (p[19] && p[19].trim() !== "") themeSingleton.wallpaperSwitcherStyle = p[19].trim();
                if (p[20] && p[20].trim() === "false") themeSingleton.showDividers = false;
                if (p[21]) { let v = parseFloat(p[21].trim()); if (!isNaN(v)) themeSingleton.rowSpacing = v; }
                if (p[22] && p[22].trim() !== "") themeSingleton.barDropdownStyle = p[22].trim();
                if (p[23] && p[23].trim() !== "") themeSingleton.barPosition = p[23].trim();
                if (p[24]) { let v = parseFloat(p[24].trim()); if (!isNaN(v)) themeSingleton.barOpacity = v; }
            }
        }
    }

    property real barOpacity: 1.0
    property bool barTransparency: false

    FileView {
        id: themeBarOpacityFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_opacity"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseFloat(t.trim());
                if (!isNaN(v)) themeSingleton.barOpacity = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseFloat(t.trim());
                if (!isNaN(v)) themeSingleton.barOpacity = v;
            }
        }
    }

    FileView {
        id: themeBarTransFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_transparency"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                themeSingleton.barTransparency = (t.trim() !== "false");
                themeSingleton.quickshellTransparency = themeSingleton.barTransparency;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                themeSingleton.barTransparency = (t.trim() !== "false");
                themeSingleton.quickshellTransparency = themeSingleton.barTransparency;
            }
        }
    }

    property int barGap: 10

    FileView {
        id: themeBarGapFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_gap"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barGap = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barGap = v;
            }
        }
    }

    property int barWindowGap: 0

    FileView {
        id: themeBarWindowGapFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_window_gap"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barWindowGap = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barWindowGap = v;
            }
        }
    }

    property int barHeight: 30

    FileView {
        id: themeBarHeightFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_height"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barHeight = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barHeight = v;
            }
        }
    }

    property int barRadius: 15

    FileView {
        id: themeBarRadiusFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_radius"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barRadius = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barRadius = v;
            }
        }
    }

    property int barSideGap: 0

    FileView {
        id: themeBarSideGapFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_side_gap"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barSideGap = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barSideGap = v;
            }
        }
    }

    property int barBorderWidth: 0

    FileView {
        id: themeBarBorderWidthFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_border_width"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barBorderWidth = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barBorderWidth = v;
            }
        }
    }

    property int barInnerPadding: 13

    FileView {
        id: themeBarInnerPaddingFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_padding"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barInnerPadding = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barInnerPadding = v;
            }
        }
    }

    property int barItemSpacing: 7

    FileView {
        id: themeBarItemSpacingFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_spacing"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barItemSpacing = v;
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let v = parseInt(t.trim());
                if (!isNaN(v)) themeSingleton.barItemSpacing = v;
            }
        }
    }

    property string barPosition: "Above"

    FileView {
        id: barPositionFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_position"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                themeSingleton.barPosition = t.trim();
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                themeSingleton.barPosition = t.trim();
            }
        }
    }

    FileView {
        id: barDropdownStyleFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.bar_dropdown_style"
        watchChanges: true
        onFileChanged: { reload(); }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                themeSingleton.barDropdownStyle = t.trim();
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                themeSingleton.barDropdownStyle = t.trim();
            }
        }
    }

    property bool isPitchBlack: false

    FileView {
        id: colorModeFileView
        path: themeSingleton.homeDir + "/.config/cupcake/.color_mode"
        watchChanges: true
        onFileChanged: {
            reload();
        }
        onTextChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let s = t.trim().toLowerCase();
                themeSingleton.isDark = (s !== "light");
                themeSingleton.isPitchBlack = (s === "pitch-black" || s === "pitch black" || s === "black");
                themeSingleton.readColorsImmediately();
            }
        }
        onLoadedChanged: {
            let t = text();
            if (t && t.trim().length > 0) {
                let s = t.trim().toLowerCase();
                themeSingleton.isDark = (s !== "light");
                themeSingleton.isPitchBlack = (s === "pitch-black" || s === "pitch black" || s === "black");
                themeSingleton.readColorsImmediately();
            }
        }
    }

    property bool quickshellTransparency: true

    property real bgAlpha: quickshellTransparency ? 0.85 : 1.0

    // Fonts
    property string defaultFontFamily: "Inter"
    property string monoFontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property string fontMono: monoFontFamily || "JetBrainsMono Nerd Font Propo"
    property real defaultFontScale: 1.0
    property real monoFontScale: 1.0

    property int defaultFontSize: 14
    property int defaultFontWeight: 500

    // App Fonts
    property string appFontFamily: "Inter"
    property string appMonoFamily: "JetBrainsMono Nerd Font Propo"
    readonly property string appFontMono: appMonoFamily || monoFontFamily || "JetBrainsMono Nerd Font Propo"
    property real appMonoScale: 1.0
    property int appFontSize: 14
    property int appFontWeight: 500

    property real sliderThickness: 2.0

    property bool showSliderThumb: true

    property bool liquidify: true

    property bool showCardBackground: true

    property string appLauncherStyle: "Hover"

    property string wallpaperSwitcherStyle: "Carousel"

    property string barDropdownStyle: "Attached"

    property bool showDividers: true

    property real rowSpacing: 4.0

    // helper function to parse hex string into color with alpha
    function transparentize(hexStr, alpha) {
        if (!hexStr || hexStr === "") hexStr = "#000000";
        var c = Qt.color(hexStr);
        if (!c || isNaN(c.r)) return Qt.rgba(0, 0, 0, alpha);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    function readColorsImmediately() {
        if (themeSingleton.isPitchBlack) {
            themeSingleton.colBackground = "#000000";
            themeSingleton.colSurface = "#000000";
            themeSingleton.colSurfaceContainer = "#000000";
            themeSingleton.colSurfaceContainerHigh = "#0d0d0d";
            themeSingleton.colSurfaceVariant = "#151515";
            themeSingleton.colOnBackground = "#FFFFFF";
            themeSingleton.colOnSurface = "#FFFFFF";
            themeSingleton.colOnSurfaceVariant = "#B0B0B0";
            themeSingleton.colOutline = "#2c2c2c";
            themeSingleton.colPrimary = "#FFFFFF";
            themeSingleton.colOnPrimary = "#000000";
            return;
        }
        var text = colorsFileView.text();
        if (text && text.trim().length > 0) {
            try {
                var c = JSON.parse(text.trim());
                if (c.background) themeSingleton.colBackground = themeSingleton.transparentize(c.background, themeSingleton.bgAlpha);
                if (c.onBackground) themeSingleton.colOnBackground = c.onBackground;
                if (c.surfaceContainerHighest) themeSingleton.colSurface = themeSingleton.transparentize(c.surfaceContainerHighest, themeSingleton.bgAlpha);
                if (c.surfaceContainer) themeSingleton.colSurfaceContainer = themeSingleton.transparentize(c.surfaceContainer, themeSingleton.bgAlpha);
                if (c.surfaceContainerHigh) themeSingleton.colSurfaceContainerHigh = themeSingleton.transparentize(c.surfaceContainerHigh, themeSingleton.bgAlpha);
                if (c.surfaceVariant) themeSingleton.colSurfaceVariant = themeSingleton.transparentize(c.surfaceVariant, themeSingleton.bgAlpha);
                if (c.onSurface) themeSingleton.colOnSurface = c.onSurface;
                if (c.onSurfaceVariant) themeSingleton.colOnSurfaceVariant = c.onSurfaceVariant;
                if (c.outline) themeSingleton.colOutline = c.outline;
                if (c.primary) themeSingleton.colPrimary = c.primary;
                if (c.onPrimary) themeSingleton.colOnPrimary = c.onPrimary;
                if (c.secondary) themeSingleton.colSecondary = c.secondary;
                if (c.error) themeSingleton.colError = c.error;
            } catch (e) {}
        }
    }

    Component.onCompleted: {
        readColorsImmediately();
    }

    FileView {
        id: colorsFileView
        path: themeSingleton.homeDir + "/.cache/quickshell_colors.json"
        watchChanges: true
        onFileChanged: {
            reload();
        }
        onTextChanged: {
            themeSingleton.readColorsImmediately();
        }
        onLoadedChanged: {
            themeSingleton.readColorsImmediately();
        }
    }

    property color colBackground: transparentize("#15121c", bgAlpha)
    property color colOnBackground: "#e8dfee"
    property color colSurface: transparentize("#37333e", bgAlpha)
    property color colSurfaceContainer: transparentize(Quickshell.env("CUPCAKE_COL_SURFACE_CONTAINER") !== "" ? Quickshell.env("CUPCAKE_COL_SURFACE_CONTAINER") : "#221e28", bgAlpha)
    property color colSurfaceContainerHigh: transparentize(Quickshell.env("CUPCAKE_COL_SURFACE_CONTAINER_HIGH") !== "" ? Quickshell.env("CUPCAKE_COL_SURFACE_CONTAINER_HIGH") : "#2c2833", bgAlpha)
    property color colSurfaceVariant: transparentize("#4a4550", bgAlpha)
    property color colOnSurface: Quickshell.env("CUPCAKE_COL_ON_SURFACE") !== "" ? Quickshell.env("CUPCAKE_COL_ON_SURFACE") : "#e8dfee"
    property color colOnSurfaceVariant: Quickshell.env("CUPCAKE_COL_ON_SURFACE_VARIANT") !== "" ? Quickshell.env("CUPCAKE_COL_ON_SURFACE_VARIANT") : "#cbc4d2"
    property color colOutline: "#958e9b"
    property color colPrimary: "#d4bbff"
    property color colOnPrimary: "#40008c"
    property color colSecondary: "#d7bde4"
    property color colError: "#ffb4ab"
}
