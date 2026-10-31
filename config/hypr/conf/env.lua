-- Qt goes through qt6ct. NOT "kde": that platform theme ships with
-- plasma-integration, which is not installed, and Qt silently falls back to an
-- unthemed default (light chrome around a dark Dolphin view).
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")

-- NVIDIA (RTX 5080)
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- Bigger shader cache (12 GB instead of NVIDIA's ~1 GB), so games don't
-- recompile shaders - and stutter - every time the small cache fills up.
hl.env("__GL_SHADER_DISK_CACHE_SIZE", "12000000000")
