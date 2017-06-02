##Adds an event for when player presses a key.

###This mod is client- and server-side.

###Added functions are:
`keyevent.register_on_keypress_bits(keys, old_keys, dtime, player_name)`
`keys`: The pressed keys in bit format.
`old_keys`: The keys pressed before.
`dtime`: Time from last check.
`player_name`: Name of the player. Client-side this is `nil`.

`keyevent.register_on_keypress(keys, old_keys, dtime, player_name)`
Same as above but `keys` and `old_keys` is given in table format.

