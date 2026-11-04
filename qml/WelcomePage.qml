import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Page {
    id: page

    title: qsTr("Biaox")

    readonly property bool dialogOpen: false

    signal openToolsRequested()

    background: Rectangle {
        color: Material.background
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 520)
        spacing: 18

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 112
            height: 112
            radius: 28
            color: "#ff9900"

            Label {
                anchors.centerIn: parent
                text: qsTr("B")
                color: "#000000"
                font.pixelSize: 68
                font.bold: true
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Biaox")
            font.pixelSize: 36
            font.bold: true
            horizontalAlignment: Qt.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("一个小工具箱")
            font.pixelSize: 16
            opacity: 0.7
            horizontalAlignment: Qt.AlignHCenter
        }

        // Label {
        //     Layout.fillWidth: true
        //     Layout.topMargin: 8
        //     text: qsTr("从左侧菜单选择一个工具开始。\n也可以点击左上角菜单按钮，或从窗口左边缘向右滑动。")
        //     font.pixelSize: 14
        //     opacity: 0.8
        //     wrapMode: Label.Wrap
        //     horizontalAlignment: Qt.AlignHCenter
        //     lineHeight: 1.25
        // }

        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            text: qsTr("打开工具箱")
            Material.background: "#ff9900"
            Material.foreground: "#171717"
            onClicked: page.openToolsRequested()
        }
    }
}
