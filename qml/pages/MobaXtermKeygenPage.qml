import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import Biaox

ScrollablePage {
    id: page

    title: qsTr("MobaXterm 注册机")

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
        status.severity = "error";
        status.text = message;
    }

    function showInfo(message) {
        status.severity = "info";
        status.text = message;
    }

    function showWarning(message) {
        status.severity = "warning";
        status.text = message;
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
        spacing: Theme.spaceXl

        Label {
            Layout.fillWidth: true
            text: qsTr("生成 MobaXterm Professional 的 Custom.mxtpro 激活文件。")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        AppSection {
            Layout.fillWidth: true
            title: qsTr("许可证信息")

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Theme.spaceLg
                rowSpacing: Theme.spaceLg

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    text: qsTr("版本号")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontLabel
                    font.weight: Theme.fontWeightMedium
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceSm

                    AppComboBox {
                        id: versionCombo
                        Layout.preferredWidth: 220
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

                    AppButton {
                        text: qsTr("刷新")
                        variant: "secondary"
                        onClicked: page.reloadVersions()
                    }

                    AppButton {
                        text: qsTr("编辑")
                        variant: "secondary"
                        onClicked: keygen.openVersionsFile()
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    text: qsTr("用户名")
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontLabel
                    font.weight: Theme.fontWeightMedium
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceSm

                    AppTextField {
                        id: nameField
                        Layout.fillWidth: true
                        placeholderText: qsTr("请输入用户名")
                        Accessible.name: qsTr("用户名")
                        onTextEdited: keygen.userName = text
                        onAccepted: page.generate()
                    }

                    AppButton {
                        Layout.preferredWidth: 88
                        text: qsTr("生成")
                        variant: "primary"
                        onClicked: page.generate()
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("版本列表文件：%1").arg(keygen.versionsFilePath)
                color: Theme.textMuted
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideMiddle
            }
        }

        AppSection {
            Layout.fillWidth: true
            title: qsTr("输出文件")

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceSm

                AppTextField {
                    id: fileField
                    Layout.fillWidth: true
                    readOnly: true
                    placeholderText: qsTr("生成并保存后显示路径")
                    text: keygen.lastSavedPath
                }

                AppButton {
                    text: qsTr("打开文件夹")
                    variant: "secondary"
                    enabled: keygen.lastSavedPath.length > 0
                    onClicked: keygen.openContainingFolder()
                }
            }

            AppStatus {
                id: status
                Layout.fillWidth: true
                text: qsTr("就绪")
                severity: "info"
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("将生成的 Custom.mxtpro 放到 MobaXterm 安装目录，然后重启 MobaXterm。")
            color: Theme.textMuted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
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
                page.showWarning(message + "\n" + qsTr("提示：文件名不是 Custom.mxtpro，MobaXterm 可能无法识别。"));
            else
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
