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
            title: qsTr("文件哈希校验")
            subtitle: qsTr("计算 MD5 / SHA-1 / SHA-256 并校验")
            source: "pages/FileHashPage.qml"
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
