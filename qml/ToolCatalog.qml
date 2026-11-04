pragma Singleton

import QtQuick

QtObject {
    readonly property ListModel tools: ListModel {
        ListElement {
            title: qsTr("MobaXterm 注册机")
            subtitle: qsTr("生成 Custom.mxtpro")
            source: "pages/MobaXtermKeygenPage.qml"
            isPlaceholder: false
        }
        ListElement {
            title: qsTr("新功能待添加")
            subtitle: qsTr("更多小工具，敬请期待")
            source: "pages/ComingSoonPage.qml"
            isPlaceholder: true
        }
    }
}
