import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Biaox

ColumnLayout {
    id: control

    property string title: ""

    spacing: Theme.spaceMd

    Label {
        Layout.fillWidth: true
        visible: control.title.length > 0
        text: control.title
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSection
        font.weight: Theme.fontWeightDemiBold
        elide: Label.ElideRight
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        visible: control.title.length > 0
        color: Theme.border
    }
}
