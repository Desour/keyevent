--[[
 __                                           __
|  | __ ____ ___.__. _______  __ ____   _____/  |_
|  |/ // __ <   |  |/ __ \  \/ // __ \ /    \   __\
|    <\  ___/\___  \  ___/\   /\  ___/|   |  \  |
|__|_ \\___  > ____|\___  >\_/  \___  >___|  /__|
     \/    \/\/         \/          \/     \/
--]]

local load_time_start = os.clock()
local modname = minetest.get_current_modname()


keyevent = {}
local keyevents_bits = {}
function keyevent.register_on_keypress_bits(func)
	keyevents_bits[#keyevents_bits+1] = func
end
local keyevents = {}
function keyevent.register_on_keypress(func)
	keyevents[#keyevents+1] = func
end

local function bits_to_table(bits)
	if type(bits) ~= "number" then
		return bits
	end
	local meaning = {
		[0] = "up", "down", "left",
		"right", "jump", "aux1",
		"sneak", "LMB", "RMB"
	}
	local t = {}
	for i = 8, 0, -1 do
		local n = 2^i
		if bits >= n then
			bits = bits - n
			t[meaning[i]] = true
		else
			t[meaning[i]] = false
		end
	end
	return t
end

local function on_step(dtime, player, old_keys, keys, player_name)
	if keys == old_keys then
		return
	end
	for i = 1, #keyevents_bits do
		keyevents_bits[i](keys, old_keys, dtime, player_name)
	end
	local keys_t = bits_to_table(keys)
	local old_keys_t = bits_to_table(old_keys)
	for i = 1, #keyevents do
		keyevents[i](keys_t, old_keys_t, dtime, player_name)
	end
	return keys
end

if INIT == "client" then
	local localplayer
	minetest.register_on_connect(function()
		localplayer = minetest.localplayer
	end)

	local keys
	local f = on_step
	function on_step(dtime)
		if not localplayer then
			return
		end
		keys = f(dtime, localplayer, keys, localplayer:get_key_pressed()) or keys
	end

elseif INIT == "game" then
	local keys = {}
	local f = on_step
	function on_step(dtime)
		local players = minetest.get_connected_players()
		for i = 1, #players do
			local player_name = players[i]:get_player_name()
			keys[player_name] = f(dtime, players[i], keys[player_name],
					players[i]:get_player_control_bits(), player_name) or
					keys[player_name]
		end
	end

else
	function on_step()
	end
end

minetest.register_globalstep(on_step)


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "["..modname.."] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
