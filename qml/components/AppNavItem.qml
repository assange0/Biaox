import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Biaox

ItemDelegate {
    id: control

    property string headline: ""
    property string description: ""
    property bool placeholder: false

    implicitHeight: Theme.navItemHeight
    hoverEnabled: true
    padding: 0
    // 与抽屉头部/页脚的 Theme.spaceXl(24) 共用同一左基线
    leftPadding: Theme.spaceXl
    rightPadding: Theme.spaceLg
    topPadding: 10
    bottomPadding: 10
    opacity: placeholder ? 0.55 : 1.0

    contentItem: ColumnLayout {
        width: control.availableWidth
        spacing: 2

        Label {
            Layout.fillWidth: true
            text: control.headline
            color: control.highlighted || control.hovered ? Theme.accentText : Theme.textPrimary
            font.pixelSize: Theme.fontSection
            font.weight: Theme.fontWeightMedium
            elide: Label.ElideRight
        }

        Label {
            Layout.fillWidth: true
            visible: control.description.length > 0
            text: control.description
            color: Theme.textSecondary
            font.pixelSize: Theme.fontCaption
            elide: Label.ElideRight
        }
    }

    background: Rectangle {
        color: control.highlighted ? Theme.selectedOverlay
            : control.hovered ? Theme.hoverOverlay
            : "transparent"

        Rectangle {
            width: 3
            height: parent.height
            color: Theme.brand
            visible: control.highlighted || control.hovered
        }
    }
}
