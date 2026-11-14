if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Greeting: fastfetch as a job ticket from 永遠堂 (Eien-dō), the carpentry
# workshop, beside its shop sign (~/.config/fastfetch/eien-do.png). The sign
# needs kitty; other terminals get just the ticket.
function fish_greeting
    set -l sign ~/.config/fastfetch/eien-do.png
    if test "$TERM" = xterm-kitty; and test -f $sign
        command fastfetch --logo-type kitty-direct --logo $sign --logo-width 9 --logo-height 13 \
            --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 3
    else
        command fastfetch
    end
end

# plain `fastfetch` shows the sign too; with options it's fastfetch as usual
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
