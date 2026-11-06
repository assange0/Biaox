pragma Singleton

import QtQuick

// Single source of truth for the Biaox look. Keep main.cpp's startup palette
// in sync with the surface/text colors used here.
QtObject {
    // Brand
    readonly property color brand: "#FF9900"
    readonly property color brandHover: "#FFAD33"
    readonly property color brandPressed: "#E68A00"
    readonly property color brandForeground: "#000000"

    // Surfaces
    readonly property color canvas: "#000000"
    readonly property color header: "#000000"
    readonly property color drawer: "#0A0A0A"
    readonly property color surface: "#121212"
    readonly property color surfaceAlt: "#1A1A1A"
    readonly property color input: "#0F0F0F"
    readonly property color border: "#2A2A2A"
    readonly property color borderStrong: "#5A5A5A"
    readonly property color headerBorder: "#1F1F1F"

    // Text
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A6A6A6"
    readonly property color textMuted: "#8A8A8A"
    readonly property color textDisabled: "#5C5C5C"

    // Semantic / state
    readonly property color warning: "#FFB74D"
    readonly property color danger: "#FF5C5C"
    readonly property color success: "#69F0AE"
    readonly property color hoverOverlay: "#14FFFFFF"
    readonly property color selectedOverlay: "#1FFF9900"
    readonly property color overlay: "#B3000000"
    readonly property color scrollThumb: "#3D3D3D"
    readonly property color scrollThumbHover: "#5A5A5A"

    // Typography
    readonly property int fontDisplay: 32
    readonly property int fontHero: 24
    readonly property int fontHeader: 18
    readonly property int fontSection: 16
    readonly property int fontBody: 15
    readonly property int fontLabel: 14
    readonly property int fontCaption: 13
    readonly property int fontBrand: 20
    readonly property int fontWeightMedium: Font.Medium
    readonly property int fontWeightDemiBold: Font.DemiBold
    readonly property int fontWeightBold: Font.Bold

    // Metrics
    readonly property int controlHeight: 36
    readonly property int iconButtonSize: 40
    readonly property int headerHeight: 56
    readonly property int pagePadding: 24
    readonly property int pageMaxWidth: 820
    readonly property int drawerWidth: 300
    readonly property int dialogMaxWidth: 480
    readonly property int menuWidth: 200
    readonly property int menuItemHeight: 40
    readonly property int navItemHeight: 56
    readonly property int radius: 4

    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16
    readonly property int spaceXl: 24
    readonly property int space2xl: 32

    readonly property int motionFast: 100
    readonly property int motionNormal: 180

    function alpha(sourceColor, opacity) {
        return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, opacity);
    }
}
