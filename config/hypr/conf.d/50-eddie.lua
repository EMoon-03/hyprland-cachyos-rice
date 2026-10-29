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
