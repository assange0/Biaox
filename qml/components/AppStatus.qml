import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Biaox

RowLayout {
    id: control

    // "info" | "success" | "warning" | "error"
    property string text: ""
    property string severity: "info"

    spacing: Theme.spaceSm
    implicitHeight: Math.max(18, statusLabel.implicitHeight)

    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: 6
        implicitWidth: 6
        implicitHeight: 6
        radius: 3
        color: control.severity === "error" ? Theme.danger
            : control.severity === "warning" ? Theme.warning
            : control.severity === "success" ? Theme.success
            : Theme.textMuted
    }

    Label {
        id: statusLabel
        Layout.fillWidth: true
        text: control.text
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontLabel
        color: control.severity === "error" ? Theme.danger
            : control.severity === "warning" ? Theme.warning
            : control.severity === "success" ? Theme.success
            : Theme.textSecondary
    }
}
