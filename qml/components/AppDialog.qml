import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Biaox

Dialog {
    id: control

    property string confirmText: qsTr("确定")
    property string cancelText: qsTr("取消")
    property bool showCancel: false

    modal: true
    focus: true
    padding: Theme.spaceXl
    topPadding: Theme.spaceXl
    bottomPadding: Theme.spaceLg

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radius
        border.width: 1
        border.color: Theme.borderStrong
    }

    header: Label {
        text: control.title
        visible: control.title.length > 0
        color: Theme.textPrimary
        font.pixelSize: Theme.fontHeader
        font.weight: Theme.fontWeightDemiBold
        leftPadding: Theme.spaceXl
        rightPadding: Theme.spaceXl
        topPadding: Theme.spaceXl
        bottomPadding: 0
        elide: Label.ElideRight
    }

    footer: Item {
        implicitHeight: footerLayout.implicitHeight + Theme.spaceXl

        RowLayout {
            id: footerLayout
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceXl
            anchors.rightMargin: Theme.spaceXl
            anchors.bottomMargin: Theme.spaceXl
            spacing: Theme.spaceSm

            Item { Layout.fillWidth: true }

            AppButton {
                visible: control.showCancel
                text: control.cancelText
                variant: "secondary"
                onClicked: control.reject()
            }

            AppButton {
                text: control.confirmText
                variant: "primary"
                focus: true
                onClicked: control.accept()
                Keys.onReturnPressed: control.accept()
            }
        }
    }

    Overlay.modal: Rectangle {
        color: Theme.overlay
    }

    Overlay.modeless: Rectangle {
        color: Theme.overlay
    }
}
