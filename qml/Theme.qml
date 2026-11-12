pragma Singleton

import QtQuick
import QtCore

// 单一颜色来源。运行期调色板由 qml/Main.qml 从这里派生；main.cpp 只设置
// 启动防白闪的 Window 底色，不重复维护颜色。
//
// 主题三选一：scheme = "system" | "dark" | "light"，通过 setScheme() 修改
// 并持久化到 QSettings（category=appearance, key=theme）。"system" 跟随
// QStyleHints::colorScheme；X11/无 portal 环境返回 Unknown 时回退深色。
QtObject {
    id: root

    // QtObject 没有默认属性，Settings 用属性初始化器持有。
    property Settings settings: Settings {
        category: "appearance"
        property string theme: "system"
    }

    property string scheme: settings.theme

    function setScheme(value) {
        settings.theme = value
    }

    readonly property bool darkMode: scheme === "dark"
        || (scheme !== "light" && Qt.styleHints.colorScheme !== Qt.Light)

    // Brand
    readonly property color brand: "#FF9900"
    readonly property color brandHover: "#FFAD33"
    readonly property color brandPressed: "#E68A00"
    readonly property color brandForeground: "#000000"
    // 橙色作为文字/描边（而非填充）时的颜色：深色沿用 brand；浅色必须加深，
    // 否则 #FF9900 文字在浅底上仅 ~2.2:1（验收红线：次要文字 ≥ 4.5:1）。
    readonly property color accentText: darkMode ? "#FF9900" : "#9A5500"
    readonly property color accentTextHover: darkMode ? "#FFAD33" : "#7A4400"

    // Surfaces
    readonly property color canvas: darkMode ? "#000000" : "#FAFAFA"
    readonly property color header: darkMode ? "#000000" : "#FAFAFA"
    readonly property color drawer: darkMode ? "#0A0A0A" : "#F0F0F0"
    readonly property color surface: darkMode ? "#121212" : "#FFFFFF"
    readonly property color surfaceAlt: darkMode ? "#1A1A1A" : "#F0F0F0"
    readonly property color input: darkMode ? "#0F0F0F" : "#FFFFFF"
    readonly property color border: darkMode ? "#2A2A2A" : "#E0E0E0"
    readonly property color borderStrong: darkMode ? "#5A5A5A" : "#B0B0B0"
    readonly property color headerBorder: darkMode ? "#1F1F1F" : "#E5E5E5"

    // Text
    readonly property color textPrimary: darkMode ? "#FFFFFF" : "#1A1A1A"
    readonly property color textSecondary: darkMode ? "#A6A6A6" : "#595959"
    readonly property color textMuted: darkMode ? "#8A8A8A" : "#6E6E6E"
    readonly property color textDisabled: darkMode ? "#6E6E6E" : "#9A9A9A"

    // Semantic / state
    readonly property color warning: darkMode ? "#FFB74D" : "#9A6200"
    readonly property color danger: darkMode ? "#FF5C5C" : "#C62828"
    readonly property color success: darkMode ? "#69F0AE" : "#1E7D4F"
    readonly property color hoverOverlay: darkMode ? "#14FFFFFF" : "#14000000"
    // 12% 品牌橙 overlay 在深/浅底上都成立；遮罩压暗内容，浅色主题用更轻的 40%
    readonly property color selectedOverlay: "#1FFF9900"
    readonly property color overlay: darkMode ? "#B3000000" : "#66000000"
    readonly property color scrollThumb: darkMode ? "#3D3D3D" : "#C0C0C0"
    readonly property color scrollThumbHover: darkMode ? "#5A5A5A" : "#A0A0A0"

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
    // 大尺寸品牌资产（96px 欢迎页 logo）的圆角；小图标仍用 radius
    readonly property int radiusLg: 8

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
