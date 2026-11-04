import QtQuick
import QtQuick.Controls
import Biaox

Menu {
    id: control

    implicitWidth: Theme.menuWidth
    padding: Theme.spaceXs
    overlap: 0

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
