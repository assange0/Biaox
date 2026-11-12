pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Biaox

ComboBox {
    id: control

    implicitWidth: 220
    implicitHeight: Theme.controlHeight
    leftPadding: Theme.spaceMd
    rightPadding: 32
    topPadding: 0
    bottomPadding: 0
    hoverEnabled: true
    activeFocusOnTab: true
    font.pixelSize: Theme.fontBody

    readonly property bool focused: activeFocus || visualFocus

    contentItem: TextField {
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        enabled: control.editable
        readOnly: !control.editable
        text: control.editable ? control.editText : control.displayText
        font: control.font
        color: control.enabled ? Theme.textPrimary : Theme.textDisabled
        selectionColor: Theme.brand
        selectedTextColor: Theme.brandForeground
        verticalAlignment: TextInput.AlignVCenter
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse
        background: null
    }

    indicator: Item {
        x: control.mirrored ? control.leftPadding : control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8

        Canvas {
            anchors.fill: parent
            property color strokeColor: !control.enabled ? Theme.textDisabled
                : (control.popup && control.popup.visible) || control.hovered || control.focused ? Theme.accentText
                : Theme.textSecondary

            onStrokeColorChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = 1.5;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.beginPath();
                ctx.moveTo(1, 2);
                ctx.lineTo(6, 7);
                ctx.lineTo(11, 2);
                ctx.stroke();
            }
        }
    }

    background: Rectangle {
        implicitWidth: 220
        implicitHeight: Theme.controlHeight
        radius: Theme.radius
        color: Theme.input
        border.width: control.focused ? 2 : 1
        border.color: !control.enabled ? Theme.border
            : control.focused ? Theme.accentText
            : Theme.borderStrong
    }

    delegate: ItemDelegate {
        id: optionItem

        required property var model
        required property int index

        width: ListView.view.width
        implicitHeight: Theme.menuItemHeight
        leftPadding: Theme.spaceMd
        rightPadding: Theme.spaceMd
        topPadding: 0
        bottomPadding: 0
        hoverEnabled: true
        text: model[control.textRole]
        highlighted: control.highlightedIndex === optionItem.index

        palette.text: control.currentIndex === optionItem.index ? Theme.accentText : Theme.textPrimary
        palette.highlightedText: Theme.accentText

        background: Rectangle {
            // 当前选中项用品牌橙 12% overlay，hover 高亮用中性 overlay；
            // 两者同时成立时选中态优先，避免选中项看起来只是 hover。
            color: control.currentIndex === optionItem.index ? Theme.selectedOverlay
                : optionItem.highlighted ? Theme.hoverOverlay
                : "transparent"

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: Theme.brand
                visible: control.currentIndex === optionItem.index
            }
        }
    }

    popup: Popup {
        y: control.height + Theme.spaceXs
        width: Math.min(control.width, 360)
        padding: Theme.spaceXs
        font: control.font
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        // Keep the popup inside the 720x480 minimum window: viewport at most
        // 6 rows (240px), plus the popup's own padding so the last row is
        // never clipped; longer version lists scroll.
        height: Math.max(Theme.controlHeight,
            Math.min(240, contentItem.implicitHeight) + topPadding + bottomPadding)

        contentItem: ListView {
            implicitHeight: contentHeight
            clip: true
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: AppScrollBar { }
        }

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radius
            border.width: 1
            border.color: Theme.borderStrong
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Theme.motionFast
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0.0
                duration: Theme.motionFast
            }
        }
    }
}
