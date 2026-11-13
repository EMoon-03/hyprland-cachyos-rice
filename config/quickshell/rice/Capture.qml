// Screenshots and screen recording, modelled on Nisfere's ScreenshotService,
// ScreenRecordService and AreaPicker - with gpu-screen-recorder, the GPU
// encoder the replay buffer already uses, in place of wf-recorder.
//
//   screenshots  ~/.local/bin/rice-shot: grim -> ~/Pictures/Screenshots, also
//                copied to the clipboard; the notification offers Open, Edit
//                (satty), Show in folder.
//   recordings   gpu-screen-recorder -> ~/Videos/Recordings: mp4, 60 fps,
//                desktop audio and optionally the mic. Stopped with SIGINT,
//                which is what makes it finish the file.
//   area         slurp: drag to select, on any monitor (Esc cancels)
//   bar          ~/.cache/rice/recording holds the start time while recording;
//                waybar's recording pill counts from it
//
// Every capture waits a moment first, so the menu or picker that started it
// has faded out of the frame.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    property bool recording: false
    property real startedAt: 0
    property int elapsed: 0
    property bool desktopAudio: true
    property bool micAudio: false
    property bool picking: false
    property var pickCallback: null

    readonly property string home: Quickshell.env("HOME")
    readonly property string shotDir: home + "/Pictures/Screenshots"
    readonly property string videoDir: home + "/Videos/Recordings"
    readonly property string elapsedText: Math.floor(elapsed / 60) + ":" + (elapsed % 60 < 10 ? "0" : "") + elapsed % 60

    function stamp() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")
    }

    function focusedMonitor() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    }

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

    // --------------------------------------------------------- screenshots --
    // screen (the focused monitor) | window (the active one) | area
    // Done by ~/.local/bin/rice-shot (grim + slurp, save, copy, notify) - the
    // same tools that work from a terminal. The pause lets the menu fade out.
    function screenshot(mode) {
        console.info("capture: rice-shot", mode)
        later(() => Quickshell.execDetached([root.home + "/.local/bin/rice-shot", mode]))
    }

    // A notification with buttons. notify-send -A waits for the click, so it
    // runs detached and does the action itself.
    function notifyFile(file, title, note, isImage) {
        Quickshell.execDetached(["bash", "-c",
            'file="$1"; title="$2"; note="$3"; image="$4"\n'
            + 'name="$(basename "$file")"\n'
            + 'if [ "$image" = yes ]; then\n'
            + '  act="$(notify-send -a Capture -i "$file" -A open=Open -A edit=Edit -A folder="Show in folder" "$title" "$name · $note")"\n'
            + 'else\n'
            + '  act="$(notify-send -a Capture -i video-x-generic -A open=Open -A folder="Show in folder" "$title" "$name · $note")"\n'
            + 'fi\n'
            + 'case "$act" in\n'
            + '  open) xdg-open "$file" ;;\n'
            + '  edit) satty --filename "$file" ;;\n'
            + '  folder) thunar "$file" ;;\n'
            + 'esac',
            "_", file, title, note, isImage ? "yes" : "no"])
    }

    // ----------------------------------------------------------- recording --
    // screen (the focused monitor) | area
    function record(mode) {
        if (recording)
            return
        if (mode === "area")
            pick(g => startRecording(["-w", "region", "-region", g.gsr]))
        else
            later(() => startRecording(["-w", focusedMonitor()]))
    }

    function toggleRecording() {
        recording ? stop() : record("screen")
    }

    function stop() {
        if (recording && recorder.running)
            recorder.signal(2)
    }

    function startRecording(target) {
        if (recorder.running)
            return
        const audio = [desktopAudio ? "default_output" : "", micAudio ? "default_input" : ""].filter(a => a).join("|")
        recorder.file = videoDir + "/Recording_" + stamp() + ".mp4"
        recorder.command = ["bash", "-c", 'mkdir -p "$1"; shift; exec "$@"', "_", videoDir,
            "gpu-screen-recorder"].concat(target,
            ["-f", "60", "-c", "mp4", "-q", "very_high", "-cursor", "yes"],
            audio ? ["-a", audio] : [],
            ["-o", recorder.file])
        recorder.running = true
        recording = true
        startedAt = Date.now()
        elapsed = 0
        stateFile.setText(Math.floor(startedAt / 1000) + "\n")
    }

    Process {
        id: recorder
        property string file: ""
        stderr: StdioCollector {
            id: recorderErrors
        }
        onExited: code => {
            root.recording = false
            stateFile.setText("\n")
            const seconds = Math.round((Date.now() - root.startedAt) / 1000)
            if (seconds >= 1 && (code === 0 || code === 130 || code === 2)) {
                root.notifyFile(file, "Recording saved",
                    Math.floor(seconds / 60) + "m " + (seconds % 60) + "s", false)
            } else {
                const lines = recorderErrors.text.trim().split("\n")
                Quickshell.execDetached(["notify-send", "-a", "Capture", "-u", "critical", "Recording failed",
                    lines[lines.length - 1] || "gpu-screen-recorder exited with " + code])
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed = Math.round((Date.now() - root.startedAt) / 1000)
    }

    FileView {
        id: stateFile
        path: root.home + "/.cache/rice/recording"
        preload: false
        blockWrites: true
    }

    // --------------------------------------------------------- area picker --
    // slurp draws the selection (drag; Esc or a click without dragging cancels).
    // It replaced a home-made overlay whose selection could vanish mid-drag.
    function pick(callback) {
        if (picking) {
            console.warn("capture: area picker already open - ignored")
            return
        }
        pickCallback = callback
        later(() => {
            root.picking = true
            slurp.running = true
        })
    }

    function finishPick(geometry) {
        picking = false
        const callback = pickCallback
        pickCallback = null
        if (callback && geometry)
            later(() => callback(geometry))
    }

    Process {
        id: slurp
        command: ["slurp", "-d", "-w", "2",
            "-b", "#00000073",
            "-c", String(Theme.primary).slice(0, 7) + "ff",
            "-s", "#00000000",
            "-f", "%x %y %w %h"]
        stdout: StdioCollector {
            id: slurpOut
        }
        stderr: StdioCollector {
            id: slurpErr
        }
        onStarted: console.info("capture: area picker (slurp) started")
        onExited: code => {
            const v = slurpOut.text.trim().split(/\s+/).map(Number)
            console.info("capture: slurp exited", code, JSON.stringify(slurpOut.text.trim()), slurpErr.text.trim())
            if (code !== 0 || v.length !== 4 || v.some(isNaN) || v[2] < 4 || v[3] < 4) {
                root.finishPick(null)
                return
            }
            const [x, y, w, h] = v          // global logical coordinates, as grim -g expects
            root.finishPick({ grim: `${x},${y} ${w}x${h}`, gsr: `${w}x${h}+${x}+${y}` })
        }
    }
}
