import QtQuick
import QtQuick.Controls
import Biaox

ToolButton {
    id: control

    implicitWidth: Theme.iconButtonSize
    implicitHeight: Theme.iconButtonSize
    padding: 8
    display: AbstractButton.IconOnly
    hoverEnabled: true
    activeFocusOnTab: true

    icon.width: 24
    icon.height: 24
    icon.color: !enabled ? Theme.textDisabled
        : (hovered || visualFocus) ? Theme.accentText
        : Theme.textPrimary

    background: Rectangle {
        implicitWidth: Theme.iconButtonSize
        implicitHeight: Theme.iconButtonSize
        radius: Theme.radius
        color: !control.enabled ? "transparent"
            : (control.down || control.hovered || control.visualFocus) ? Theme.hoverOverlay
            : "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accentText

        Behavior on color {
            ColorAnimation { duration: Theme.motionFast }
        }
    }
}
