// Screenshot review: after a shot is taken (rice-shot ... ask), a small card
// over the dimmed screen shows the picture with four choices under it:
//
//   Save    to ~/Pictures/Screenshots (and copied)        Enter or S
//   Copy    to the clipboard only, no file                C
//   Edit    save it and open it in satty to draw on       E
//   Cancel  throw it away                                 Esc, or click outside
//
// The shot waits in a temporary file until then; the choice is carried out by
// `rice-shot finish <choice> <file>`.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property string file: ""
    property bool open: false
    property var targetScreen: null

    function review(path) {
        file = path
        targetScreen = focusedScreen()
        open = true
    }

    function choose(choice) {
        if (!open)
            return
        open = false
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/rice-shot", "finish", choice, file])
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === name)
                return screens[i]
        return screens[0]
    }

    component Choice: Rectangle {
        id: choice
        property string icon: ""
        property string label: ""
        property string key: ""
        property bool accent: false
        signal clicked

        Layout.fillWidth: true
        implicitHeight: 30
        radius: 9
        color: area.containsMouse ? Theme.alpha(Theme.primary, accent ? 0.30 : 0.16)
                                  : (accent ? Theme.alpha(Theme.primary, 0.18) : Theme.alpha(Theme.surface_container_high, 0.85))
        border.width: 1
        border.color: area.containsMouse || accent ? Theme.alpha(Theme.primary, 0.55) : Theme.alpha(Theme.outline_variant, 0.45)

        Row {
            anchors.centerIn: parent
            spacing: 6

            LucideIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: choice.icon
                size: 13
                color: Theme.primary
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: choice.label
                color: Theme.on_surface
                font.family: Theme.font
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: choice.key
                color: Theme.on_surface_variant
                font.family: Theme.font
                font.pixelSize: 9
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.clicked()
        }
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
            exclusionMode: ExclusionMode.Ignore
            color: Qt.rgba(0, 0, 0, 0.35)
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "rice-shot-review"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // click outside the card = Cancel
            MouseArea {
                anchors.fill: parent
                onClicked: root.choose("cancel")
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.max(360, preview.paintedWidth + 28)
                height: column.implicitHeight + 28
                radius: 16
                color: Theme.alpha(Theme.surface_container, 0.96)
                border.width: 1
                border.color: Theme.alpha(Theme.outline_variant, 0.5)

                focus: true
                Component.onCompleted: forceActiveFocus()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.choose("cancel")
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_S) root.choose("save")
                    else if (event.key === Qt.Key_C) root.choose("copy")
                    else if (event.key === Qt.Key_E) root.choose("edit")
                    else return
                    event.accepted = true
                }

                MouseArea {                        // clicks on the card don't cancel
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: column
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "Screenshot"
                        color: Theme.on_surface_variant
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: preview.paintedWidth
                        implicitHeight: preview.paintedHeight
                        radius: 8
                        clip: true
                        color: "transparent"

                        Image {
                            id: preview
                            anchors.centerIn: parent
                            // never larger than the shot itself, at most 640 x 380
                            width: Math.min(640, Math.max(1, implicitWidth))
                            height: Math.min(380, Math.max(1, implicitHeight))
                            source: root.file ? "file://" + root.file : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                            smooth: true
                            mipmap: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Choice { icon: "save"; label: "Save"; key: "S"; accent: true; onClicked: root.choose("save") }
                        Choice { icon: "clipboard"; label: "Copy"; key: "C"; onClicked: root.choose("copy") }
                        Choice { icon: "paintbrush"; label: "Edit"; key: "E"; onClicked: root.choose("edit") }
                        Choice { icon: "x"; label: "Cancel"; key: "Esc"; onClicked: root.choose("cancel") }
                    }
                }
            }
        }
    }
}
