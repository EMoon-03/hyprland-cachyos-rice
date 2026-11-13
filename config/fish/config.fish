if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Greeting: fastfetch beside a small Roman statue face from wallhaven
# (~/.local/share/rice/statue.png; `rice-statue next` for another one). Only in
# kitty, which can show pictures. If there's no picture yet, it's fetched in the
# background for the next terminal and this one shows just the info.
function fish_greeting
    set -l pic ~/.local/share/rice/statue.png
    if test "$TERM" = xterm-kitty; and test -f $pic
        fastfetch --logo-type kitty-direct --logo $pic --logo-width 20 --logo-height 10 \
            --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 3
    else
        fastfetch
        if test "$TERM" = xterm-kitty; and not test -f $pic; and command -q rice-statue
            rice-statue >/dev/null 2>&1 &
            disown
        end
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
