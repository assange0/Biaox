import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Page {
    id: page

    title: qsTr("新功能待添加")

    readonly property bool dialogOpen: false

    background: Rectangle {
        color: Material.background
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 460)
        spacing: 18

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 96
            height: 96
            radius: 48
            color: "transparent"
            border.width: 2
            border.color: "#ff9900"

            Label {
                anchors.centerIn: parent
                text: "+"
                color: "#ff9900"
                font.pixelSize: 52
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("新功能待添加")
            font.pixelSize: 28
            font.bold: true
            horizontalAlignment: Qt.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("后续的小工具会出现在这里")
            font.pixelSize: 16
            opacity: 0.7
            wrapMode: Label.Wrap
            horizontalAlignment: Qt.AlignHCenter
        }
    }
}
