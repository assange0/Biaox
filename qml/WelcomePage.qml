import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Biaox

BiaoxPage {
    id: page

    title: qsTr("Biaox")

    signal openToolsRequested()

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 520)
        spacing: Theme.spaceLg

        Image {
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/icons/biaox/app.png"
            sourceSize.width: 96
            sourceSize.height: 96
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spaceSm
            text: qsTr("Biaox")
            color: Theme.textPrimary
            font.pixelSize: Theme.fontDisplay
            font.weight: Theme.fontWeightBold
            horizontalAlignment: Qt.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("一个小工具箱")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Qt.AlignHCenter
        }

        AppButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.spaceSm
            Layout.preferredWidth: 180
            text: qsTr("打开工具箱")
            variant: "primary"
            onClicked: page.openToolsRequested()
        }
    }
}
