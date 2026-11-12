import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Biaox

// 单个哈希算法行：算法名 + 匹配徽标 + 只读值 + 复制按钮。
// FileHashPage 用三份实例替代原来的复制粘贴代码块。
RowLayout {
    id: control

    property string algorithm: ""
    property string value: ""
    property bool matched: false

    signal copyRequested(string algorithm, string value)

    spacing: Theme.spaceSm

    RowLayout {
        Layout.alignment: Qt.AlignVCenter
        // 固定标签列宽，保证三行的值输入框左缘对齐
        Layout.preferredWidth: 104
        Layout.maximumWidth: 104
        spacing: Theme.spaceSm

        Label {
            Layout.fillWidth: true
            text: control.algorithm
            color: control.matched ? Theme.success : Theme.textSecondary
            font.pixelSize: Theme.fontLabel
            font.weight: Theme.fontWeightMedium
            elide: Text.ElideRight
        }

        Label {
            visible: control.matched
            text: qsTr("匹配")
            color: Theme.success
            font.pixelSize: Theme.fontCaption
            font.weight: Theme.fontWeightMedium
        }
    }

    AppTextField {
        Layout.fillWidth: true
        readOnly: true
        text: control.value
        placeholderText: qsTr("计算后显示")
        font.pixelSize: Theme.fontLabel
        Accessible.name: qsTr("%1 哈希值").arg(control.algorithm)
    }

    AppButton {
        Layout.preferredWidth: 72
        text: qsTr("复制")
        variant: "secondary"
        enabled: control.value.length > 0
        Accessible.name: qsTr("复制 %1 哈希值").arg(control.algorithm)
        onClicked: control.copyRequested(control.algorithm, control.value)
    }
}
