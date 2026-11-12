import QtQuick
import QtQuick.Controls
import Biaox

Menu {
    id: control

    implicitWidth: Theme.menuWidth
    padding: Theme.spaceXs
    overlap: 0

    // 在这个文本的菜单项上方画一条分隔线（用于"退出"这类终止性动作）。
    // MenuSeparator 与自定义 delegate 不兼容（Qt 6.12 实测不渲染），
    // 所以用显式属性实现。
    property string dividerBeforeText: ""

    delegate: MenuItem {
        id: menuItem

        implicitHeight: Theme.menuItemHeight
        leftPadding: Theme.spaceMd
        rightPadding: Theme.spaceMd
        topPadding: 0
        bottomPadding: 0
        font.pixelSize: Theme.fontBody

        palette.text: Theme.textPrimary
        palette.windowText: menuItem.highlighted && menuItem.enabled ? Theme.brand : Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.brand

        background: Rectangle {
            color: menuItem.highlighted && menuItem.enabled ? Theme.surfaceAlt : "transparent"
            radius: 2

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Theme.border
                visible: menuItem.text === control.dividerBeforeText
            }
        }
    }

    contentItem: ListView {
        implicitHeight: contentHeight
        model: control.contentModel
        interactive: contentHeight > height
        clip: true
        currentIndex: control.currentIndex
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: AppScrollBar { }
    }

    background: Rectangle {
        implicitWidth: Theme.menuWidth
        color: Theme.surface
        radius: Theme.radius
        border.width: 1
        border.color: Theme.borderStrong
    }
}
