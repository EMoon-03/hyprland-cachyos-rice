-- Eddie's extra binds (loaded after conf/binds.lua and the menu's overrides).
--
-- Hyprland has no minimise, so "minimised" windows go to a hidden special
-- workspace instead:
--   SUPER + Z            minimise the focused window
--   SUPER + SHIFT + Z    show / hide the minimised windows
--   SUPER + ALT + Z      (while they're shown) bring the focused one back
-- Moving a window to the other monitor needs nothing new:
--   SUPER + SHIFT + 6    to the vertical monitor (workspaces 6-10 live there)
--   SUPER + SHIFT + 1    back to the main one (workspaces 1-5)
--   or hold SUPER and drag it across with the left mouse button

local dsp = hl.dsp

rice.bind("SUPER + Z", function()
    hl.dispatch(dsp.window.move({ workspace = "special:minimized" }))
    hl.dispatch(dsp.workspace.toggle_special("minimized"))   -- moving there opens it; close it again
end)
rice.bind("SUPER + SHIFT + Z", dsp.workspace.toggle_special("minimized"))
rice.bind("SUPER + ALT + Z", dsp.window.move({ workspace = "e+0" }))  -- out of the special workspace

-- USB drives ------------------------------------------------------------------
--   plugged in           mounted for you, with a notification (udiskie)
--   SUPER + SHIFT + E    eject every USB drive; a notification says when it's
--                        safe to pull out (or use the ⏏ next to it in Thunar)
if not os.getenv("RICE_NO_AUTOSTART") then
    hl.on("hyprland.start", function()
        hl.exec_cmd("sh -c 'command -v udiskie >/dev/null && exec udiskie --no-tray --automount --notify'")
        hl.exec_cmd("~/.local/bin/thunar-tidy")   -- sidebar, thumbnails, "Open in Yazi" (safe to repeat)
    end)

    -- Games (Proton/X11) ask XWayland for the "primary" monitor to pick their
    -- resolution; unset, they took the side one and offered 1920x1080 at most.
    -- XWayland forgets it whenever a monitor sleeps, wakes or changes, so it is
    -- set again each time (and at login, and on every reload).
    local function main_primary()
        hl.exec_cmd("sh -c 'sleep 1; for i in 1 2 3 4 5 6 7 8 9 10; do xrandr --output DP-2 --primary >/dev/null 2>&1 && exit 0; sleep 1; done'")
    end
    hl.on("hyprland.start", main_primary)
    hl.on("monitor.added", main_primary)
    hl.on("monitor.layout_changed", main_primary)
    hl.on("config.reloaded", main_primary)
end
rice.bind("SUPER + SHIFT + E", dsp.exec_cmd(
    "sh -c 'udiskie-umount -a --detach && notify-send -i drive-removable-media \"USB\" \"Safe to unplug\" "
 .. "|| notify-send -u critical -i drive-removable-media \"USB still in use\" \"Close anything open on the drive, then try again\"'"))

-- Files --------------------------------------------------------------------------
--   SUPER + E    Thunar (mouse: drag and drop, drives, "show in folder")
--   SUPER + Y    Yazi (keyboard, with previews); T inside Yazi opens Thunar there
rice.bind("SUPER + Y", dsp.exec_cmd("kitty --class yazi -e yazi"))

-- Thunar's pop-ups open where you clicked, not in the middle of the screen ----
-- (confirm "empty trash?", rename, properties... and the copy/delete progress
-- window, which would otherwise take a whole tile). Kept fully on screen.
local at_cursor = {
    "max(min(cursor_x-(window_w*0.5),monitor_w-window_w),0)",
    "max(min(cursor_y-(window_h*0.5),monitor_h-window_h),0)",
}
hl.window_rule({
    name  = "thunar-dialogs-at-cursor",
    match = { class = "^([Tt]hunar)$", float = true },
    move  = at_cursor,
})
hl.window_rule({
    name  = "thunar-progress-small",
    match = { class = "^([Tt]hunar)$", title = "^(File Operation Progress)$" },
    float = true,
    size  = { 460, 140 },
    move  = at_cursor,
})

-- Apps open where they belong ------------------------------------------------
--   side monitor:  Discord on 6, YouTube Music on 7, btop (CTRL + ALT + DELETE) on 8
--   main monitor:  Vivaldi, on whichever main workspace is showing
--   Steam and games already go to workspace 1, fullscreen (conf/rules.lua)
-- Only where a window first opens; move it anywhere afterwards as usual.
-- If an app doesn't land there, `hyprctl clients | grep class` shows its real name.
hl.window_rule({
    name      = "discord-to-side",
    match     = { class = "(?i)^(discord|vesktop|legcord|webcord)$" },
    workspace = "6",
})
hl.window_rule({
    name      = "music-to-side",   -- Pear Desktop / YouTube Music app, or Vivaldi's web-app version
    match     = { class = [[(?i)^(.*youtube[-_ .]?music.*|.*pear[-_ .]?desktop.*|.*music\.youtube\.com.*)$]] },
    workspace = "7",
})
hl.window_rule({
    name      = "btop-to-side",
    match     = { class = "^(taskmgr|btop)$" },
    workspace = "8",
})
hl.window_rule({
    name    = "vivaldi-on-main",
    match   = { class = "(?i)^vivaldi(-stable)?$" },
    monitor = "DP-2",
})

-- Fullscreen video in Vivaldi (YouTube, Twitch...) --------------------------
-- The main monitor turns VRR on for anything fullscreen (vrr = 2). Switching it
-- on makes the screen blank for a moment, and Vivaldi can drop out of
-- fullscreen when that happens - so the browser never switches it. Games
-- still get VRR. And the screens stay on while a video plays fullscreen.
hl.window_rule({
    name         = "vivaldi-fullscreen-video",
    match        = { class = "(?i)^vivaldi.*$" },
    no_vrr       = true,
    idle_inhibit = "fullscreen",
})

-- No blank screen when anything goes fullscreen: don't tell the monitor "video
-- is playing" (it switches picture mode, and blanks while it does) and don't
-- auto-switch it to HDR.
hl.config({ render = { send_content_type = false, cm_auto_hdr = 0 } })

-- Side monitor ----------------------------------------------------------------
--   SUPER + SHIFT + O    portrait <-> landscape, after you turn it (side-monitor)
rice.bind("SUPER + SHIFT + O", dsp.exec_cmd("~/.local/bin/side-monitor toggle"))
