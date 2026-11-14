if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Greeting: fastfetch as a Servant's status sheet beside the seal of Ur-Nungal,
# king of Uruk: his name in gold cuneiform on lapis (~/.config/fastfetch/
# ur-nungal.png). The seal needs kitty; other terminals get just the sheet.
function fish_greeting
    set -l seal ~/.config/fastfetch/ur-nungal.png
    if test "$TERM" = xterm-kitty; and test -f $seal
        command fastfetch --logo-type kitty-direct --logo $seal --logo-width 26 --logo-height 13 \
            --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 3
    else
        command fastfetch
    end
end

# plain `fastfetch` shows the seal too; with options it's fastfetch as usual
function fastfetch
    if test (count $argv) -eq 0
        fish_greeting
    else
        command fastfetch $argv
    end
end

# `y`: Yazi, and when you quit it the terminal is left in the folder you were in.
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# `fetch` prints it again (handy after resizing the window).
function fetch
    fish_greeting
end
