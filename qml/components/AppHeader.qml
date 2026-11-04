import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Biaox

ToolBar {
    id: control

    property string title: ""
    property bool brandMode: false
    property string backIconName: "drawer"
    property string backAccessibleName: qsTr("打开工具箱菜单")
    property string menuAccessibleName: qsTr("更多选项")

    signal backClicked()
    signal menuClicked()

    implicitHeight: Theme.headerHeight
    padding: 0

    background: Rectangle {
        implicitHeight: Theme.headerHeight
        color: Theme.header

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.headerBorder
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceSm
        anchors.rightMargin: Theme.spaceSm
        spacing: Theme.spaceXs

        AppIconButton {
            icon.name: control.backIconName
            Accessible.name: control.backAccessibleName
            onClicked: control.backClicked()
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spaceXs
            text: control.brandMode ? "Biaox" : control.title
            color: control.brandMode ? Theme.brand : Theme.textPrimary
            font.pixelSize: control.brandMode ? Theme.fontBrand : Theme.fontHeader
            font.weight: control.brandMode ? Theme.fontWeightBold : Theme.fontWeightDemiBold
            font.letterSpacing: control.brandMode ? 0.5 : 0
            elide: Label.ElideRight
            verticalAlignment: Qt.AlignVCenter
        }

        AppIconButton {
            icon.name: "menu"
            Accessible.name: control.menuAccessibleName
            onClicked: control.menuClicked()
        }
    }
}
