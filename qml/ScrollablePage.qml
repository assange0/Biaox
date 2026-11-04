// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls

Page {
    id: page

    // Tool pages that open their own dialog can bind this to the dialog's
    // visibility so the application's Back shortcut stays disabled.
    property bool dialogOpen: false

    // contentData (rather than contentItem) keeps non-visual objects such as
    // MobaKeygen, FileDialog and Connections valid page content too.
    default property alias content: pane.contentData

    Flickable {
        anchors.fill: parent
        contentHeight: pane.implicitHeight
        flickableDirection: Flickable.AutoFlickIfNeeded

        Pane {
            id: pane
            width: parent.width
            padding: 20
        }

        ScrollIndicator.vertical: ScrollIndicator { }
    }
}
