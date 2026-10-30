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
end
rice.bind("SUPER + SHIFT + E", dsp.exec_cmd(
    "sh -c 'udiskie-umount -a --detach && notify-send -i drive-removable-media \"USB\" \"Safe to unplug\" "
 .. "|| notify-send -u critical -i drive-removable-media \"USB still in use\" \"Close anything open on the drive, then try again\"'"))

-- Files --------------------------------------------------------------------------
--   SUPER + E    Thunar (mouse: drag and drop, drives, "show in folder")
--   SUPER + Y    Yazi (keyboard, with previews); T inside Yazi opens Thunar there
rice.bind("SUPER + Y", dsp.exec_cmd("kitty --class yazi -e yazi"))
