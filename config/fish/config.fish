if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Greeting: the arcade screen (local/bin/arcade-fetch). It prints fastfetch, then
# Pac-Man runs across the attract row and every dot adds to the 1UP score, which
# carries over between terminals. ARCADE_NO_ANIM=1 skips the run.
# The old picture/GIF greeting is still there: ~/.local/bin/rice-fetch.sh
function fish_greeting
    ~/.local/bin/arcade-fetch
end

# `fetch` prints it again (handy after resizing the window).
function fetch
    ~/.local/bin/arcade-fetch
end
