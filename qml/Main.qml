pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Biaox

ApplicationWindow {
    id: window

    width: 960
    height: 640
    minimumWidth: 720
    minimumHeight: 480
    visible: true
    title: currentPageTitle.length > 0 ? qsTr("Biaox - %1").arg(currentPageTitle) : qsTr("Biaox")

    color: Theme.canvas
    font.pixelSize: Theme.fontBody

    // 运行期调色板单一来源：全部从 Theme token 派生（Basic-style 的原生弹层
    // 如文本框右键菜单也走这里）。main.cpp 只负责启动防白闪的 Window 底色。
    palette.window: Theme.canvas
    palette.windowText: Theme.textPrimary
    palette.base: Theme.input
    palette.alternateBase: Theme.surfaceAlt
    palette.text: Theme.textPrimary
    palette.button: Theme.surfaceAlt
    palette.buttonText: Theme.textPrimary
    palette.highlight: Theme.brand
    palette.highlightedText: Theme.brandForeground
    palette.placeholderText: Theme.textMuted
    palette.mid: Theme.borderStrong
    palette.dark: Theme.border

    readonly property BiaoxPage currentPage: stackView.currentItem as BiaoxPage
    readonly property string currentPageTitle: stackView.depth > 1 && currentPage ? currentPage.title : ""

    // Do not let the global Back shortcut navigate away while a drawer, menu
    // or dialog is open; those popups handle Escape themselves.
    readonly property bool modalOpen: drawer.opened || optionsMenu.opened || aboutDialog.opened || (stackView.depth > 1 && currentPage && currentPage.dialogOpen)

    Shortcut {
        sequences: ["Esc", "Back"]
        enabled: stackView.depth > 1 && !window.modalOpen
        onActivated: {
            stackView.pop();
            listView.currentIndex = -1;
        }
    }

    header: AppHeader {
        id: appHeader
        brandMode: stackView.depth === 1
        title: window.currentPageTitle
        backIconName: stackView.depth > 1 ? "back" : "drawer"
        backAccessibleName: stackView.depth > 1 ? qsTr("返回") : qsTr("打开工具箱菜单")
        menuAccessibleName: qsTr("更多选项")

        onBackClicked: {
            if (stackView.depth > 1) {
                stackView.pop();
                listView.currentIndex = -1;
            } else {
                drawer.open();
            }
        }

        onMenuClicked: optionsMenu.open()
    }

    AppMenu {
        id: optionsMenu
        // 右缘与顶栏菜单按钮右缘对齐（按钮右侧距窗口 8px），顶部紧贴 header 底边。
        x: window.width - Theme.spaceSm - width
        y: 0
        dividerBeforeTexts: [qsTr("主题：跟随系统"), qsTr("退出")]

        Action {
            text: qsTr("关于 Biaox")
            onTriggered: aboutDialog.open()
        }

        Action {
            text: qsTr("主题：跟随系统")
            checkable: true
            checked: Theme.scheme === "system"
            onTriggered: Theme.setScheme("system")
        }

        Action {
            text: qsTr("主题：深色")
            checkable: true
            checked: Theme.scheme === "dark"
            onTriggered: Theme.setScheme("dark")
        }

        Action {
            text: qsTr("主题：浅色")
            checkable: true
            checked: Theme.scheme === "light"
            onTriggered: Theme.setScheme("light")
        }

        Action {
            text: qsTr("退出")
            onTriggered: Qt.quit()
        }
    }

    Drawer {
        id: drawer
        width: Math.min(Theme.drawerWidth, window.width * 0.8)
        height: window.height
        edge: Qt.LeftEdge
        modal: true
        interactive: stackView.depth === 1
        padding: 0

        background: Rectangle {
            color: Theme.drawer

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 1
                color: Theme.headerBorder
            }
        }

        Overlay.modal: Rectangle {
            color: Theme.overlay
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spaceXl
                spacing: Theme.spaceMd

                Image {
                    Layout.alignment: Qt.AlignVCenter
                    source: "qrc:/icons/biaox/app.png"
                    sourceSize.width: 32
                    sourceSize.height: 32
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        text: "Biaox"
                        color: Theme.accentText
                        font.pixelSize: Theme.fontBrand
                        font.weight: Theme.fontWeightBold
                        font.letterSpacing: 0.5
                        elide: Label.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("一个小工具箱")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontCaption
                        elide: Label.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                focus: true
                currentIndex: -1
                model: ToolCatalog.tools
                boundsBehavior: Flickable.StopAtBounds

                delegate: AppNavItem {
                    id: navItem

                    required property int index
                    required property string title
                    required property string subtitle
                    required property string source
                    required property bool isPlaceholder

                    width: ListView.view.width
                    headline: title
                    description: subtitle
                    placeholder: isPlaceholder
                    highlighted: ListView.isCurrentItem
                    Accessible.name: subtitle.length > 0 ? title + "，" + subtitle : title

                    onClicked: {
                        if (stackView.depth > 1)
                            return;
                        listView.currentIndex = index;
                        stackView.push(Qt.resolvedUrl(source));
                        drawer.close();
                    }
                }

                ScrollBar.vertical: AppScrollBar { }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            Label {
                Layout.fillWidth: true
                Layout.margins: Theme.spaceXl
                text: qsTr("Biaox 版本 %1").arg(Qt.application.version)
                color: Theme.textMuted
                font.pixelSize: Theme.fontCaption
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

    AppDialog {
        id: aboutDialog
        title: qsTr("关于 Biaox")
        // Popup 坐标空间从 header 之下的 contentItem 开始，用 contentItem 的
        // 尺寸居中（旧实现用 window.height，多算了 56px header 导致整体偏低）。
        x: Math.round((window.contentItem.width - width) / 2)
        y: Math.round((window.contentItem.height - height) / 2)
        width: Math.min(window.width - 48, Theme.dialogMaxWidth)
        confirmText: qsTr("确定")

        ColumnLayout {
            width: aboutDialog.availableWidth
            spacing: Theme.spaceMd

            Label {
                Layout.fillWidth: true
                text: qsTr("Biaox %1").arg(Qt.application.version)
                color: Theme.textPrimary
                font.pixelSize: Theme.fontHeader
                font.weight: Theme.fontWeightBold
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("一个基于 Qt 6 和 Qt Quick Controls 的小工具箱。")
                color: Theme.textPrimary
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spaceSm
                text: qsTr("MobaXterm 是商业软件。本工具仅供学习研究，请通过官方渠道购买正版授权，请勿用于商业用途。")
                color: Theme.textSecondary
                font.pixelSize: Theme.fontLabel
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spaceSm
                text: qsTr("部分界面结构和图标来自 Qt Quick Controls Gallery（BSD-3-Clause）。")
                color: Theme.textMuted
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.WordWrap
            }
        }
    }
}
