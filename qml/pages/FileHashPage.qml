import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import Biaox

ScrollablePage {
    id: page

    title: qsTr("文件哈希校验")
    dialogOpen: fileDialog.visible

    property string copyMessage: ""
    property bool copyFailed: false
    property string dropWarning: ""

    function openFileDialog() {
        dropWarning = "";
        fileDialog.open();
    }

    function acceptFile(url) {
        dropWarning = "";
        copyMessage = "";
        hasher.setFile(url);
    }

    function copyHash(algorithm, value) {
        if (hasher.copyToClipboard(value)) {
            copyFailed = false;
            copyMessage = qsTr("已复制 %1 到剪贴板").arg(algorithm);
        } else {
            copyFailed = true;
            copyMessage = qsTr("复制失败");
        }
        copyTimer.restart();
    }

    function fileStatusText() {
        if (!hasher.hasFile)
            return "";

        if (hasher.errorMessage.length > 0)
            return hasher.errorMessage;
        if (hasher.busy)
            return qsTr("%1 · 正在计算…").arg(hasher.fileSizeText);
        if (hasher.hasResult)
            return qsTr("%1 · 计算完成").arg(hasher.fileSizeText);
        return qsTr("%1 · 尚未计算").arg(hasher.fileSizeText);
    }

    function fileStatusSeverity() {
        return hasher.errorMessage.length > 0 ? "error" : "info";
    }

    function verifyText() {
        if (hasher.matchState === "invalid")
            return hasher.expectedHashError;
        if (hasher.matchState === "match")
            return qsTr("校验通过：%1 一致").arg(hasher.matchedAlgorithm);
        if (hasher.matchState === "mismatch")
            return qsTr("校验未通过：与 %1 结果不一致").arg(hasher.expectedAlgorithm);
        if (hasher.busy)
            return qsTr("计算完成后自动比对");

        if (hasher.matchState === "empty") {
            if (hasher.hasResult)
                return qsTr("计算完成；粘贴来源网站提供的哈希值即可比对");
            if (hasher.hasFile)
                return qsTr("点击“计算”开始");
            return qsTr("选择文件并点击“计算”，然后粘贴哈希值比对");
        }

        return hasher.hasFile
            ? qsTr("点击“计算”开始")
            : qsTr("请选择文件");
    }

    function verifySeverity() {
        if (hasher.matchState === "match")
            return "success";
        if (hasher.matchState === "mismatch")
            return "error";
        if (hasher.matchState === "invalid")
            return "warning";
        return "info";
    }

    FileHasher {
        id: hasher
    }

    Timer {
        id: copyTimer
        interval: 2000
        onTriggered: page.copyMessage = ""
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceMd

        Label {
            Layout.fillWidth: true
            text: qsTr("选择文件后点击“计算”，再粘贴来源网站提供的哈希值即可比对。")
            color: Theme.textSecondary
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
        }

        AppSection {
            Layout.fillWidth: true
            title: qsTr("文件")

            DropArea {
                id: fileDrop
                Layout.fillWidth: true
                implicitHeight: fileContent.implicitHeight + Theme.spaceXs * 2
                enabled: !hasher.busy

                // The visual drop target uses the existing flat surfaces. Reset
                // this when a drag leaves so the hint and border stay accurate.
                property bool validDrag: false

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    // 用 surface 底 + 弱描边与输入框(input + borderStrong)区分，
                    // 避免拖放区看起来像"第四个输入框"。
                    color: fileDrop.containsDrag ? Theme.selectedOverlay : Theme.surface
                    border.width: 1
                    border.color: !fileDrop.containsDrag ? Theme.border
                        : fileDrop.validDrag ? Theme.brand
                        : Theme.danger
                }

                ColumnLayout {
                    id: fileContent
                    anchors.fill: parent
                    anchors.margins: Theme.spaceXs
                    spacing: Theme.spaceMd

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !hasher.hasFile
                        spacing: Theme.spaceXs

                        Label {
                            Layout.fillWidth: true
                            text: fileDrop.containsDrag
                                ? (fileDrop.validDrag
                                    ? qsTr("松开鼠标以选择文件")
                                    : qsTr("一次只能选择一个本地文件"))
                                : qsTr("将文件拖到这里")
                            color: fileDrop.containsDrag && !fileDrop.validDrag
                                ? Theme.danger
                                : Theme.textPrimary
                            font.pixelSize: Theme.fontSection
                            font.weight: Theme.fontWeightMedium
                            horizontalAlignment: Qt.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("或点击“选择文件”从磁盘选择单个文件")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontCaption
                            horizontalAlignment: Qt.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        AppButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: Theme.spaceXs
                            text: qsTr("选择文件")
                            variant: "primary"
                            Accessible.name: qsTr("选择要校验的文件")
                            onClicked: page.openFileDialog()
                        }

                        AppStatus {
                            Layout.fillWidth: true
                            visible: hasher.errorMessage.length > 0
                            text: hasher.errorMessage
                            severity: "error"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: hasher.hasFile
                        spacing: Theme.spaceXs

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceSm

                            Label {
                                id: filePathLabel
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: hasher.filePath
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontBody
                                elide: Text.ElideMiddle
                                ToolTip.visible: pathHover.hovered
                                ToolTip.text: hasher.filePath
                                ToolTip.delay: 400

                                HoverHandler {
                                    id: pathHover
                                }
                            }

                            AppButton {
                                text: qsTr("更换")
                                variant: "secondary"
                                enabled: !hasher.busy
                                Accessible.name: qsTr("更换要校验的文件")
                                onClicked: page.openFileDialog()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceSm

                            AppStatus {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: page.fileStatusText()
                                severity: page.fileStatusSeverity()
                            }

                            AppButton {
                                Layout.preferredWidth: 72
                                text: qsTr("计算")
                                variant: "primary"
                                enabled: hasher.hasFile && !hasher.busy
                                Accessible.name: qsTr("计算文件哈希")
                                onClicked: hasher.compute()
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: fileDrop.containsDrag
                                ? (fileDrop.validDrag
                                    ? qsTr("松开鼠标以替换当前文件")
                                    : qsTr("一次只能选择一个本地文件"))
                                : qsTr("也可以拖拽新的单个文件到此面板替换")
                            color: fileDrop.containsDrag && !fileDrop.validDrag
                                ? Theme.danger
                                : Theme.textMuted
                            font.pixelSize: Theme.fontCaption
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                onEntered: (drag) => {
                    fileDrop.validDrag = drag.hasUrls
                        && drag.urls.length === 1
                        && hasher.canAcceptFile(drag.urls[0]);
                    // Never let a file-manager Move action remove the source file.
                    drag.action = Qt.CopyAction;
                    drag.accepted = fileDrop.validDrag;
                }

                onExited: fileDrop.validDrag = false

                onDropped: (drop) => {
                    if (!drop.hasUrls) {
                        page.dropWarning = qsTr("请拖入一个本地文件");
                        return;
                    }
                    if (drop.urls.length !== 1) {
                        page.dropWarning = qsTr("一次只能选择一个文件");
                        return;
                    }
                    drop.action = Qt.CopyAction;
                    page.acceptFile(drop.urls[0]);
                }
            }

            AppStatus {
                Layout.fillWidth: true
                visible: page.dropWarning.length > 0
                text: page.dropWarning
                severity: "warning"
            }
        }

        AppSection {
            Layout.fillWidth: true
            title: qsTr("哈希值")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                HashRow {
                    Layout.fillWidth: true
                    algorithm: "MD5"
                    value: hasher.md5
                    matched: hasher.matchedAlgorithm === "MD5"
                    onCopyRequested: (algorithm, value) => page.copyHash(algorithm, value)
                }

                HashRow {
                    Layout.fillWidth: true
                    algorithm: "SHA-1"
                    value: hasher.sha1
                    matched: hasher.matchedAlgorithm === "SHA-1"
                    onCopyRequested: (algorithm, value) => page.copyHash(algorithm, value)
                }

                HashRow {
                    Layout.fillWidth: true
                    algorithm: "SHA-256"
                    value: hasher.sha256
                    matched: hasher.matchedAlgorithm === "SHA-256"
                    onCopyRequested: (algorithm, value) => page.copyHash(algorithm, value)
                }

                Label {
                    Layout.fillWidth: true
                    visible: page.copyMessage.length > 0
                    text: page.copyMessage
                    color: page.copyFailed ? Theme.danger : Theme.textMuted
                    font.pixelSize: Theme.fontCaption
                    wrapMode: Text.WordWrap
                }
            }
        }

        AppSection {
            Layout.fillWidth: true
            title: qsTr("校验")

            AppTextField {
                id: expectedField
                Layout.fillWidth: true
                placeholderText: qsTr("粘贴 MD5 / SHA-1 / SHA-256，自动识别算法与常见格式")
                Accessible.name: qsTr("预期哈希值")
                onTextEdited: hasher.expectedHash = text
            }

            AppStatus {
                Layout.fillWidth: true
                text: page.verifyText()
                severity: page.verifySeverity()
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("MD5 和 SHA-1 仅适合校验文件完整性，不适合作为安全校验。")
            color: Theme.textMuted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("选择要校验的文件")
        fileMode: FileDialog.OpenFile
        acceptLabel: qsTr("选择")
        rejectLabel: qsTr("取消")
        onAccepted: page.acceptFile(selectedFile)
    }
}
