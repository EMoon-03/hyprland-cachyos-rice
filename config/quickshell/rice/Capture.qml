// Screenshots, done by the shell itself (no separate script).
//
//   screenshot(mode)   area | screen | window. Takes the shot into a temporary
//                      file, then either shows the review card (ShotReview.qml:
//                      Save / Copy / Edit / Cancel) or, with "Ask what to do"
//                      off, saves and copies it straight away.
//   finish(choice, f)  what Save / Copy / Edit / Cancel do:
//                        save    ~/Pictures/Screenshots, copied, notification
//                                (Open / Edit / Show in folder)
//                        copy    clipboard only; the notification has a Save
//                                button in case you want it after all
//                        edit    saved, copied, opened in satty (the drawing is
//                                saved beside it as ..._edited.png)
//                        cancel  thrown away
//
// slurp and grim run detached and report back with
// `qs -c rice ipc call capture taken <file>`: started as a child process of
// the shell, slurp never showed on screen. The pause before each shot lets the
// menu that started it fade out of the frame.
import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    // Ask after each shot (on), or save and copy straight away (off). Remembered.
    property bool askShots: Toggles.get("askShots", true)
    onAskShotsChanged: Toggles.set("askShots", askShots)

    property var review: null          // ShotReview, set in shell.qml

    readonly property string home: Quickshell.env("HOME")
    readonly property string shotDir: home + "/Pictures/Screenshots"
    readonly property string pendingDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/rice-shot"

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

    function sh(script, ...args) {
        Quickshell.execDetached(["bash", "-c", script, "_"].concat(args.map(String)))
    }

    function notifyError(message) {
        Quickshell.execDetached(["notify-send", "-a", "Capture", "-u", "critical", "Screenshot failed", message])
    }

    // ------------------------------------------------------------- taking --
    function screenshot(mode) {
        const name = "Screenshot_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png"
        const file = pendingDir + "/" + name
        const accent = String(Theme.primary).slice(0, 7) + "ff"
        console.info("capture: screenshot", mode, file)

        // Each one ends by handing the file back (empty = cancelled,
        // "error:..." = failed). Old leftovers in the temporary folder are cleared.
        const prep = 'f="$1"; mkdir -p "$(dirname "$f")"; '
            + 'find "$(dirname "$f")" -name "*.png" -mmin +60 -delete 2>/dev/null; '
        const back = 'qs -c rice ipc call capture taken "$r"'
        let script
        if (mode === "area") {
            // dim the screen, the selection in the theme colour; Esc cancels
            script = prep + 'r=""; '
                + 'if g="$(slurp -d -w 2 -b "#000000aa" -c "$2" -s "#00000000")"; then '
                + '  if grim -g "$g" "$f"; then r="$f"; else r="error:grim could not capture the area"; fi; '
                + 'fi; ' + back
        } else if (mode === "window") {
            script = prep
                + 'g="$(hyprctl activewindow -j | jq -r \'select(.at) | "\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"\')"; '
                + 'if [ -z "$g" ]; then r="error:no focused window"; '
                + 'elif grim -g "$g" "$f"; then r="$f"; else r="error:grim could not capture the window"; fi; ' + back
        } else {
            // the monitor the mouse is on
            script = prep
                + 'm="$(hyprctl monitors -j | jq -r \'.[] | select(.focused) | .name\')"; '
                + 'if grim ${m:+-o "$m"} "$f"; then r="$f"; else r="error:grim could not capture the screen"; fi; ' + back
        }
        later(() => sh(script, file, accent))
    }

    // the result of screenshot(), from the IPC call above
    function taken(result) {
        result = String(result || "")
        console.info("capture: taken", JSON.stringify(result))
        if (!result)
            return                                   // Esc: cancelled, no message
        if (result.startsWith("error:"))
            return notifyError(result.slice(6))
        if (askShots && review)
            review.review(result)
        else
            finish("save", result)
    }

    // ------------------------------------------------------------ finishing --
    function finish(choice, file) {
        const name = file.split("/").pop()
        const saved = shotDir + "/" + name
        const edited = shotDir + "/" + name.replace(/\.png$/, "_edited.png")
        console.info("capture: finish", choice, name)

        if (choice === "cancel") {
            sh('rm -f "$1"', file)
            return
        }
        if (choice === "copy") {
            // stays in the temporary folder for the preview and the Save button
            sh('wl-copy --type image/png < "$1"; '
                + 'act="$(notify-send -a Capture -i "$1" -A save=Save -A edit=Edit '
                + '"Screenshot copied" "Not saved · press Save to keep it in Pictures/Screenshots")"; '
                + 'case "$act" in '
                + '  save) mkdir -p "$(dirname "$2")" && cp "$1" "$2" '
                + '        && notify-send -a Capture -i "$2" "Screenshot saved" "$4 · in Pictures/Screenshots" ;; '
                + '  edit) mkdir -p "$(dirname "$3")" && satty --filename "$1" --output-filename "$3" ;; '
                + 'esac', file, saved, edited, name)
            return
        }
        // save or edit: into Screenshots, copied, notified
        sh('mkdir -p "$(dirname "$2")" && mv "$1" "$2" || exit 1; '
            + 'wl-copy --type image/png < "$2"; '
            + '[ "$5" = edit ] && satty --filename "$2" --output-filename "$3" & '
            + 'act="$(notify-send -a Capture -i "$2" -A open=Open -A edit=Edit -A folder="Show in folder" '
            + '"Screenshot saved" "$4 · in Pictures/Screenshots · copied to the clipboard")"; '
            + 'case "$act" in '
            + '  open) xdg-open "$2" ;; '
            + '  edit) satty --filename "$2" --output-filename "$3" ;; '
            + '  folder) thunar "$(dirname "$2")" ;; '
            + 'esac', file, saved, edited, name, choice)
    }
}
