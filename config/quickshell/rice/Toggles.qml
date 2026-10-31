pragma Singleton

// On/off switches that survive a restart, a log-out or a reboot: the desktop
// visualiser, clock and lyrics, and night light. (Do not disturb is kept by
// NotifService, light/dark by rice-wallpaper.)
//
// Kept in ~/.local/state/rice/toggles.json - not ~/.cache, so clearing the
// cache doesn't turn things back on. Delete the file to go back to defaults.
//
//   Toggles.get("visualiser", true)     the saved value, or the default
//   Toggles.set("visualiser", false)    save it
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Plain JS storage on purpose: reading it inside a binding (enabled:
    // Toggles.get(...)) must not tie that binding to later saves.
    readonly property var store: ({ read: false, values: {} })

    function load() {
        if (store.read)
            return
        store.read = true
        try {
            const parsed = JSON.parse(file.text() || "{}")
            store.values = parsed && typeof parsed === "object" ? parsed : {}
        } catch (e) {
            store.values = {}
        }
    }

    function get(name, fallback) {
        load()
        return typeof store.values[name] === "boolean" ? store.values[name] : fallback
    }

    function set(name, value) {
        load()
        if (store.values[name] === value)
            return
        store.values[name] = value
        file.setText(JSON.stringify(store.values, null, 2) + "\n")
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/rice/toggles.json"
        blockLoading: true      // read before the widgets decide whether to start
        printErrors: false      // no file yet = all defaults
    }
}
