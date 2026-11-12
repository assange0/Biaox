import QtQuick
import QtQuick.Controls
import Biaox

Menu {
    id: control

    implicitWidth: Theme.menuWidth
    padding: Theme.spaceXs
    overlap: 0

    // 在这些文本的菜单项上方各画一条分隔线（用于"退出"这类终止性动作）。
    // MenuSeparator 与自定义 delegate 不兼容（Qt 6.12 实测不渲染），
    // 所以用显式属性实现。
    property var dividerBeforeTexts: []

    delegate: MenuItem {
        id: menuItem

        implicitHeight: Theme.menuItemHeight
        // Basic 风格下 checkable 项为 indicator 预留 24+6=30px；不可勾选项
        // 补同样的左内边距，让所有项的文本左缘对齐。
        leftPadding: Theme.spaceMd + (menuItem.checkable ? 0 : 30)
        rightPadding: Theme.spaceMd
        topPadding: 0
        bottomPadding: 0
        font.pixelSize: Theme.fontBody

        palette.text: Theme.textPrimary
        palette.windowText: menuItem.highlighted && menuItem.enabled ? Theme.accentText : Theme.textPrimary
        palette.buttonText: Theme.textPrimary
        palette.highlightedText: Theme.accentText

        background: Rectangle {
            color: menuItem.highlighted && menuItem.enabled ? Theme.surfaceAlt : "transparent"
            radius: 2

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Theme.border
                visible: control.dividerBeforeTexts.indexOf(menuItem.text) !== -1
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
