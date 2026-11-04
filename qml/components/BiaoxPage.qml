import QtQuick
import QtQuick.Controls
import Biaox

// Base page for every Biaox screen. It centralizes the dark canvas and the
// dialogOpen contract used by Main.qml's Back shortcut.
Page {
    id: page

    property bool dialogOpen: false

    background: Rectangle {
        color: Theme.canvas
    }
}
