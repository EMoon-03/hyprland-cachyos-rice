// Capture menu (Super+Shift+S, or the bar's screenshot button): screenshot
// the screen, a window or an area. The work itself is in Capture.qml.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool open: false
    property var capture: null
    property var targetScreen: null

    function show() {
        if (open)
            return
        targetScreen = focusedScreen()
        open = true
    }

    function close() {
        open = false
    }

    function toggle() {
        open ? close() : show()
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === name)
                return screens[i]
        return screens[0]
    }

    component Tile: Rectangle {
        id: tile
        property string icon: ""
        property string label: ""
        signal clicked

        Layout.fillWidth: true
        implicitHeight: 88
        radius: 18
        color: tileArea.containsMouse ? Theme.alpha(Theme.primary, 0.16) : Theme.alpha(Theme.surface_container_high, 0.85)
        border.width: 1
        border.color: tileArea.containsMouse ? Theme.alpha(Theme.primary, 0.6) : Theme.alpha(Theme.outline_variant, 0.45)

        Column {
            anchors.centerIn: parent
            spacing: 8

            LucideIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                icon: tile.icon
                size: 24
                color: Theme.primary
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                color: Theme.on_surface
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    component SectionLabel: Text {
        Layout.leftMargin: 4
        Layout.topMargin: 4
        color: Theme.on_surface_variant
        font.family: Theme.font
        font.pixelSize: 12
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            screen: root.targetScreen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore       // over the bar, so clicking it closes
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "rice-capture"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Rectangle {
                id: panel
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Theme.barHeight + 8
                anchors.rightMargin: 10
                width: 420
                height: content.implicitHeight + 36
                radius: 26
                color: Theme.alpha(Theme.surface_container, 0.97)
                border.width: 1
                border.color: Theme.alpha(Theme.outline_variant, 0.7)

                transformOrigin: Item.TopRight
                opacity: 0
                scale: 0.96
                Component.onCompleted: {
                    opacity = 1
                    scale = 1
                    keys.forceActiveFocus()
                }
                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                }

                Item {
                    id: keys
                    focus: true
                    Keys.onEscapePressed: root.close()
                }

                ColumnLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 10

                    Text {
                        Layout.leftMargin: 4
                        text: "Capture"
                        color: Theme.on_surface
                        font.family: Theme.font
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }

                    // --------------------------------------------- screenshot --
                    SectionLabel {
                        text: "Screenshot"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Tile {
                            icon: "monitor"
                            label: "Screen"
                            onClicked: {
                                root.close()
                                root.capture.screenshot("screen")
                            }
                        }

                        Tile {
                            icon: "app-window"
                            label: "Window"
                            onClicked: {
                                root.close()
                                root.capture.screenshot("window")
                            }
                        }

                        Tile {
                            icon: "crop"
                            label: "Area"
                            onClicked: {
                                root.close()
                                root.capture.screenshot("area")
                            }
                        }
                    }

                    // ask what to do after each screenshot, or just save + copy (remembered)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: saveRow.implicitHeight + 20
                        radius: 18
                        color: Theme.alpha(Theme.surface_container_high, 0.85)

                        RowLayout {
                            id: saveRow
                            anchors.fill: parent
                            anchors.margins: 10
                            anchors.leftMargin: 16
                            spacing: 12

                            LucideIcon {
                                icon: root.capture && root.capture.askShots ? "list-checks" : "save"
                                size: 17
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: "Ask what to do"
                                    color: Theme.on_surface
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                }

                                Text {
                                    text: root.capture && root.capture.askShots
                                        ? "save, copy, edit or cancel after each shot" : "saved and copied straight away"
                                    color: Theme.on_surface_variant
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                }
                            }

                            CcSwitch {
                                checked: root.capture ? root.capture.askShots : true
                                onToggled: root.capture.askShots = !root.capture.askShots
                            }
                        }
                    }

                    // ------------------------------------------------ folders --
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 8

                        Repeater {
                            model: [
                                { icon: "image", label: "Screenshots", dir: root.capture ? root.capture.shotDir : "" }
                            ]

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: 14
                                color: folderArea.containsMouse ? Theme.alpha(Theme.on_surface, 0.08) : "transparent"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    LucideIcon {
                                        icon: modelData.icon
                                        size: 16
                                        color: Theme.on_surface_variant
                                    }

                                    Text {
                                        text: modelData.label
                                        color: Theme.on_surface_variant
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                    }
                                }

                                MouseArea {
                                    id: folderArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.close()
                                        Quickshell.execDetached(["bash", "-c", 'mkdir -p "$1" && exec thunar "$1"', "_", modelData.dir])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
