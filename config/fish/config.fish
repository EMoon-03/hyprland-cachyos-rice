if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Greeting: fastfetch beside Michelangelo's David, as ASCII art
# (~/.local/share/rice/statue.txt) or, with `rice-statue picture`, the photo
# (kitty only). `rice-statue next` for another picture of him. If there's none
# yet, it's fetched in the background for the next terminal and this one shows
# just the info.
function fish_greeting
    set -l dir ~/.local/share/rice
    set -l mode ascii
    test -f $dir/statue.mode; and set mode (cat $dir/statue.mode)
    set -l pad --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 3
    if test $mode = picture; and test "$TERM" = xterm-kitty; and test -f $dir/statue.png
        fastfetch --logo-type kitty-direct --logo $dir/statue.png --logo-width 20 --logo-height 10 $pad
    else if test -f $dir/statue.txt
        fastfetch --logo-type file-raw --logo $dir/statue.txt $pad
    else
        fastfetch
        if not test -f $dir/statue.txt; and command -q rice-statue
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
