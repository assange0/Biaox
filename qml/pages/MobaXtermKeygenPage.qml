import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs

import Biaox

ScrollablePage {
    id: page

    title: qsTr("MobaXterm注册机")

    dialogOpen: saveDialog.visible

    function generate() {
        keygen.userName = nameField.text;
        keygen.version = versionCombo.currentText;
        if (keygen.generateLicense()) {
            saveDialog.currentFile = keygen.defaultOutputUrl;
            saveDialog.selectedFile = keygen.defaultOutputUrl;
            saveDialog.open();
        }
    }

    function showError(message) {
        statusLabel.error = true;
        statusLabel.text = message;
    }

    function showInfo(message) {
        statusLabel.error = false;
        statusLabel.text = message;
    }

    function reloadVersions() {
        const typed = versionCombo.currentText;
        keygen.reloadVersions();

        const index = versionCombo.find(keygen.version);
        if (index >= 0)
            versionCombo.currentIndex = index;
        else
            versionCombo.editText = typed;
    }

    MobaKeygen {
        id: keygen
    }

    ColumnLayout {
        width: parent.width
        spacing: 16

        // Label {
        //     Layout.fillWidth: true
        //     wrapMode: Label.Wrap
        //     text: qsTr("生成 MobaXterm Professional 的 Custom.mxtpro 激活文件。")
        // }

        Frame {
            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width
                spacing: 14

                Label {
                    text: qsTr("许可证信息")
                    font.pixelSize: 20
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 10

                    Label {
                        text: qsTr("版本号")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ComboBox {
                            id: versionCombo
                            Layout.fillWidth: true
                            editable: false
                            model: keygen.versionList
                            Accessible.name: qsTr("MobaXterm 版本号")
                            onActivated: keygen.version = currentText
                            onAccepted: keygen.version = currentText

                            Component.onCompleted: {
                                const index = find(keygen.version);
                                if (index >= 0)
                                    currentIndex = index;
                                else
                                    editText = keygen.version;
                            }
                        }

                        ToolButton {
                            text: qsTr("刷新")
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("重新加载版本列表文件")
                            onClicked: page.reloadVersions()
                        }

                        ToolButton {
                            text: qsTr("编辑")
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("编辑版本列表文件：%1").arg(keygen.versionsFilePath)
                            onClicked: keygen.openVersionsFile()
                        }
                    }
                    Label {
                        text: qsTr("用户名")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: nameField
                            Layout.preferredWidth: versionCombo.width
                            placeholderText: qsTr("请输入用户名")
                            Accessible.name: qsTr("用户名")
                            onTextEdited: keygen.userName = text
                            onAccepted: page.generate()
                        }

                        Button {
                            text: qsTr("生成")
                            Material.background: "#ff9900"
                            Material.foreground: "#171717"
                            onClicked: page.generate()
                        }
                    }
                }
            }
        }

        Frame {
            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width
                spacing: 14

                Label {
                    text: qsTr("输出文件")
                    font.pixelSize: 20
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: fileField
                        Layout.fillWidth: true
                        readOnly: true
                        placeholderText: qsTr("生成并保存后显示路径")
                        text: keygen.lastSavedPath
                    }

                    Button {
                        text: qsTr("打开文件夹")
                        enabled: keygen.lastSavedPath.length > 0
                        onClicked: keygen.openContainingFolder()
                    }
                }

                Label {
                    id: statusLabel
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("就绪")
                    color: error ? "#ff9900" : Material.foreground
                    property bool error: false
                }
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Label.Wrap
            font.pixelSize: 14
            opacity: 0.72
            text: qsTr("将生成的 Custom.mxtpro 放到 MobaXterm 安装目录，然后重启 MobaXterm。")
        }
    }

    FileDialog {
        id: saveDialog
        title: qsTr("保存 MobaXterm 激活文件")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("MobaXterm 激活文件 (*.mxtpro)")]
        defaultSuffix: "mxtpro"
        acceptLabel: qsTr("保存")
        rejectLabel: qsTr("取消")
        onAccepted: keygen.saveLicense(selectedFile)
        onRejected: page.showInfo(qsTr("已取消保存"))
    }

    Connections {
        target: keygen

        function onErrorOccurred(message) {
            page.showError(message);
        }

        function onLicenseSaved(path) {
            let message = qsTr("已保存: %1").arg(path);
            if (!/[\\/]Custom\.mxtpro$/i.test(path))
                message += "\n" + qsTr("提示：文件名不是 Custom.mxtpro，MobaXterm 可能无法识别。");
            page.showInfo(message);
        }

        function onVersionListChanged() {
            const index = versionCombo.find(keygen.version);
            if (index >= 0)
                versionCombo.currentIndex = index;
        }

        function onVersionChanged() {
            const index = versionCombo.find(keygen.version);
            if (index >= 0)
                versionCombo.currentIndex = index;
            else if (versionCombo.currentText !== keygen.version)
                versionCombo.editText = keygen.version;
        }
    }
}
