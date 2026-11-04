import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import Biaox

ApplicationWindow {
    id: window

    width: 960
    height: 640
    minimumWidth: 720
    minimumHeight: 480
    visible: true
    title: currentPageTitle.length > 0 ? qsTr("Biaox - %1").arg(currentPageTitle) : qsTr("Biaox")

    Material.theme: Material.Dark
    Material.accent: "#ff9900"
    Material.primary: "#121212"
    // Material.foreground: "#f5f5f5"
    // Material.background: "#1b1b1b"
    font.pixelSize: 15

    readonly property string currentPageTitle: stackView.depth > 1 && stackView.currentItem ? stackView.currentItem.title : ""

    // Do not let the global Back shortcut navigate away while a drawer, menu
    // or dialog is open; those popups handle Escape themselves.
    readonly property bool modalOpen: drawer.opened || optionsMenu.opened || aboutDialog.opened || (stackView.depth > 1 && stackView.currentItem && stackView.currentItem.dialogOpen)

    Shortcut {
        sequences: ["Esc", "Back"]
        enabled: stackView.depth > 1 && !window.modalOpen
        onActivated: {
            stackView.pop();
            listView.currentIndex = -1;
        }
    }

    Action {
        id: navigateBackAction
        icon.name: stackView.depth > 1 ? "back" : "drawer"
        onTriggered: {
            if (stackView.depth > 1) {
                stackView.pop();
                listView.currentIndex = -1;
            } else {
                drawer.open();
            }
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: 8

            ToolButton {
                action: navigateBackAction
                icon.color: "white"
                Accessible.name: stackView.depth > 1 ? qsTr("返回") : qsTr("打开工具箱菜单")
            }

            Label {
                text: window.currentPageTitle.length > 0 ? window.currentPageTitle : qsTr("Biaox")
                font.pixelSize: 26
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            ToolButton {
                icon.name: "menu"
                icon.color: "white"
                Accessible.name: qsTr("更多选项")

                Menu {
                    id: optionsMenu
                    x: parent.width - width
                    transformOrigin: Menu.TopRight

                    Action {
                        text: qsTr("关于 Biaox")
                        onTriggered: aboutDialog.open()
                    }
                    Action {
                        text: qsTr("退出")
                        onTriggered: Qt.quit()
                    }
                }

                onClicked: optionsMenu.open()
            }
        }
    }

    Drawer {
        id: drawer
        width: Math.min(320, window.width * 0.8)
        height: window.height
        edge: Qt.LeftEdge
        modal: true
        interactive: stackView.depth === 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Label {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 16
                text: qsTr("Biaox")
                font.pixelSize: 26
                font.bold: true
                elide: Label.ElideRight
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.bottomMargin: 16
                text: qsTr("一个小工具箱")
                font.pixelSize: 16
                opacity: 0.75
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.rgba(1, 1, 1, 0.12)
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                focus: true
                currentIndex: -1
                model: ToolCatalog.tools

                delegate: ItemDelegate {
                    id: toolDelegate
                    width: ListView.view.width
                    highlighted: ListView.isCurrentItem
                    opacity: isPlaceholder ? 0.72 : 1.0

                    required property int index
                    required property string title
                    required property string subtitle
                    required property string source
                    required property bool isPlaceholder

                    readonly property url pageUrl: Qt.resolvedUrl(source)

                    contentItem: ColumnLayout {
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            text: toolDelegate.title
                            color: hovered ? "#ff9900" : "#ffffff"
                            font.pixelSize: 20
                            elide: Label.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            text: toolDelegate.subtitle
                            color: hovered ? "#ff9900" : "#ffffff"
                            font.pixelSize: 16
                            opacity: 0.65
                            elide: Label.ElideRight
                        }
                    }

                    // background: Rectangle {
                    //     anchors.fill: parent
                    //     // opacity: enabled ? 1 : 0.3
                    //     color: hovered ? "#525252" : "transparent"
                    // }

                    onClicked: {
                        if (stackView.depth > 1)
                            return;
                        listView.currentIndex = index;
                        stackView.push(pageUrl);
                        drawer.close();
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.rgba(1, 1, 1, 0.12)
            }

            Label {
                Layout.fillWidth: true
                Layout.margins: 16
                text: qsTr("Biaox 版本 %1").arg(Qt.application.version)
                opacity: 0.5
                font.pixelSize: 14
                elide: Label.ElideRight
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: WelcomePage {
            onOpenToolsRequested: drawer.open()
        }
    }

    Dialog {
        id: aboutDialog
        modal: true
        focus: true
        title: qsTr("关于 Biaox")
        x: Math.round((window.width - width) / 2)
        y: Math.round(window.height / 8)
        width: Math.min(window.width - 40, 480)
        contentHeight: aboutColumn.height

        standardButtons: Dialog.Ok

        Column {
            id: aboutColumn
            spacing: 14

            Label {
                width: aboutDialog.availableWidth
                text: qsTr("Biaox %1").arg(Qt.application.version)
                font.pixelSize: 20
                font.bold: true
            }

            Label {
                width: aboutDialog.availableWidth
                text: qsTr("一个基于 Qt 6 和 Qt Quick Controls 的小工具箱。")
                wrapMode: Label.Wrap
            }

            Label {
                width: aboutDialog.availableWidth
                text: qsTr("MobaXterm 是商业软件。本工具仅供学习研究，请通过官方渠道购买正版授权。")
                opacity: 0.8
                wrapMode: Label.Wrap
            }

            Label {
                width: aboutDialog.availableWidth
                text: qsTr("部分界面结构和图标来自 Qt Quick Controls Gallery（BSD-3-Clause）。")
                opacity: 0.6
                font.pixelSize: 14
                wrapMode: Label.Wrap
            }
        }
    }
}
