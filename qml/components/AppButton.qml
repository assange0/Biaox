import QtQuick
import QtQuick.Controls
import Biaox

Button {
    id: control

    // "primary" | "secondary" | "ghost"
    property string variant: "secondary"

    readonly property bool primaryStyle: variant === "primary"
    readonly property bool ghostStyle: variant === "ghost"
    readonly property bool hoveredStyle: hovered && enabled
    readonly property bool pressedStyle: pressed && enabled

    readonly property color contentColor: !enabled ? Theme.textDisabled
        : primaryStyle ? Theme.brandForeground
        : ghostStyle ? ((hoveredStyle || visualFocus) ? Theme.brandHover : Theme.brand)
        : ((hoveredStyle || visualFocus) ? Theme.brand : Theme.textPrimary)

    readonly property color baseColor: primaryStyle
        ? (!enabled ? Theme.surfaceAlt : pressedStyle ? Theme.brandPressed : hoveredStyle ? Theme.brandHover : Theme.brand)
        : (!enabled ? "transparent" : (pressedStyle || hoveredStyle) ? Theme.hoverOverlay : "transparent")

    // 禁用态保留弱描边，兼顾"不可点"信号与按钮可识别性（文字对比度见 textDisabled）
    readonly property color borderColor: !enabled ? Theme.border
        : visualFocus ? (primaryStyle ? Theme.textPrimary : Theme.brand)
        : primaryStyle ? "transparent"
        : ghostStyle ? "transparent"
        : Theme.borderStrong

    readonly property int borderWidth: visualFocus ? 2
        : primaryStyle ? 0
        : ghostStyle ? 0
        : 1

    implicitWidth: Math.max(72, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Theme.controlHeight

    leftPadding: Theme.spaceLg
    rightPadding: Theme.spaceLg
    topPadding: 0
    bottomPadding: 0

    hoverEnabled: true
    activeFocusOnTab: true
    font.pixelSize: Theme.fontBody
    font.weight: Theme.fontWeightDemiBold

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.contentColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 72
        implicitHeight: Theme.controlHeight
        radius: Theme.radius
        color: control.baseColor
        border.width: control.borderWidth
        border.color: control.borderColor

        Behavior on color {
            ColorAnimation { duration: Theme.motionFast }
        }
    }
}
