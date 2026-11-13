// Screenshots (no screen recording in this fork).
//
//   ~/.local/bin/rice-shot does the work: slurp to pick an area, grim to take
//   it, then either the review card (ShotReview.qml: Save / Copy / Edit /
//   Cancel) or straight to ~/Pictures/Screenshots + the clipboard.
//
// Every shot waits a moment first, so the menu that started it has faded out
// of the frame.
import QtQuick
import Quickshell

Scope {
    id: root

    // Screenshots: ask after each one - Save / Copy / Edit / Cancel (on), or
    // save and copy straight away (off). Remembered.
    property bool askShots: Toggles.get("askShots", true)
    onAskShotsChanged: Toggles.set("askShots", askShots)

    readonly property string home: Quickshell.env("HOME")
    readonly property string shotDir: home + "/Pictures/Screenshots"

    Timer {
        id: delay
        property var job: null
        interval: 400
        onTriggered: {
            const j = job
            job = null
            if (j)
                j()
        }
    }

    function later(job) {
        delay.job = job
        delay.restart()
    }

    // screen (the focused monitor) | window (the active one) | area
    function screenshot(mode) {
        console.info("capture: rice-shot", mode)
        const args = [root.home + "/.local/bin/rice-shot", mode]
        if (askShots)
            args.push("ask")
        later(() => Quickshell.execDetached(args))
    }
}
