import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Biaox

BiaoxPage {
    id: page

    title: qsTr("新功能待添加")

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 460)
        spacing: Theme.spaceLg

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 72
            implicitHeight: 72
            radius: Theme.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.brand

            Label {
                anchors.centerIn: parent
                text: "+"
                color: Theme.brand
                font.pixelSize: 36
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spaceSm
            text: qsTr("新功能待添加")
            color: Theme.textPrimary
            font.pixelSize: Theme.fontHero
            font.weight: Theme.fontWeightBold
            horizontalAlignment: Qt.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("后续的小工具会出现在这里")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
            horizontalAlignment: Qt.AlignHCenter
        }
    }
}
