import QtQuick
import QtQuick.Controls
import Biaox

ScrollBar {
    id: control

    policy: ScrollBar.AsNeeded
    minimumSize: 0.08
    padding: 1
    interactive: true
    hoverEnabled: true

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: 3
        color: control.pressed || control.hovered ? Theme.scrollThumbHover : Theme.scrollThumb
        opacity: control.policy === ScrollBar.AlwaysOn
            || (control.policy !== ScrollBar.AlwaysOff && control.size < 1.0) ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionFast }
        }
    }

    background: null
}
