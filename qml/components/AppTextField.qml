import QtQuick
import QtQuick.Controls
import Biaox

TextField {
    id: control

    implicitHeight: Theme.controlHeight
    leftPadding: Theme.spaceMd
    rightPadding: Theme.spaceMd
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: TextInput.AlignVCenter

    hoverEnabled: true
    activeFocusOnTab: true
    font.pixelSize: Theme.fontBody

    color: !enabled ? Theme.textDisabled
        : readOnly ? Theme.textSecondary
        : Theme.textPrimary
    selectionColor: Theme.brand
    selectedTextColor: Theme.brandForeground
    placeholderTextColor: Theme.textMuted

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: Theme.controlHeight
        radius: Theme.radius
        color: Theme.input
        border.width: control.activeFocus ? 2 : 1
        border.color: !control.enabled ? Theme.border
            : control.activeFocus ? Theme.accentText
            : Theme.borderStrong
    }
}
