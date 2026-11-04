// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls

import Biaox

BiaoxPage {
    id: page

    // Tool pages that open their own dialog can bind the inherited dialogOpen
    // property to the dialog's visibility so the Back shortcut stays disabled.
    // contentData (rather than contentItem) keeps non-visual objects such as
    // MobaKeygen, FileDialog and Connections valid page content too.
    default property alias content: pane.contentData

    Flickable {
        anchors.fill: parent
        contentHeight: pane.implicitHeight
        flickableDirection: Flickable.AutoFlickIfNeeded
        boundsBehavior: Flickable.StopAtBounds

        Pane {
            id: pane
            width: Math.min(parent.width - Theme.pagePadding * 2, Theme.pageMaxWidth)
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: Theme.pagePadding
            bottomPadding: Theme.pagePadding
            leftPadding: 0
            rightPadding: 0
            background: null
        }

        ScrollBar.vertical: AppScrollBar { }
    }
}
