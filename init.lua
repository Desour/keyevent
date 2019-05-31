
-- helpers:

local meaning = {
	[0] = "up", "down", "left",
	"right", "jump", "aux1",
	"sneak", "LMB", "RMB"
}

local function bits_to_table(bits)
	if type(bits) ~= "number" then
		return bits
	end
	local t = {}
	for i = #meaning, 0, -1 do
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

local function table_to_bits(t)
	if type(t) ~= "table" then
		return t
	end
	local bits = 0
	for i = 0, #meaning do
		if t[meaning[i]] then
			bits = bits + 2^i
		end
	end
	return bits
end

local function make_true(t)
	local out = {}
	for i = 1, #t do
		out[t[i]] = true
	end
	for i = 0, #meaning do
		out[meaning[i]] = out[meaning[i]] or false
	end
	return out
end

local function look_differences(bitsa, bitsb)
	if not bitsb then
		return 511
	end
	local diff = 0
	for i = #meaning, 0, -1 do
		local n = 2^i
		local a = bitsa - n >= 0
		local b = bitsb - n >= 0
		if a ~= b  then
			diff = diff + n
		end
		bitsa = bitsa - ((a and n) or 0)
		bitsb = bitsb - ((b and n) or 0)
	end
	return diff
end

local function is_different(diff_shall, diff_is)
	if diff_shall == 511 then
		return true
	end
	for i = #meaning, 0, -1 do
		local n = 2^i
		local a = diff_shall - n >= 0
		local b = diff_is - n >= 0
		if a and b then
			return true
		end
		diff_shall = diff_shall - ((a and n) or 0)
		diff_is = diff_is - ((b and n) or 0)
	end
	return false
end

local function handle_keys(keys, func)
	local keyst = type(keys)
	if keyst == "function" then
		func = keys
		keys = 511
	elseif keyst == "string" then
		for i = 0, #meaning do
			if keys == meaning[i] then
				keys = 2^i
				break
			end
		end
	elseif keyst == "table" then
		keys = table_to_bits((#keys >= 1 and make_true(keys)) or keys)
	elseif keyst ~= "number" then
		keys = 511
	end
	return keys, func
end

local function add_func_to_callback_origins(func)
	-- this is taken from minetest/builtin/game/register.lua
	minetest.callback_origins[func] = {
		mod = core.get_current_modname() or "??",
		name = debug.getinfo(1, "n").name or "??"
	}
end
--------------------------------------------------------------------------------

-- global functions:

keyevent = {}

local keyevents_bits = {}
function keyevent.register_on_keypress_bits(keys, func)
	keys, func = handle_keys(keys, func)
	add_func_to_callback_origins(func)
	if not keyevents_bits[keys] then
		keyevents_bits[keys] = {func}
		return
	end
	keyevents_bits[keys][#keyevents_bits[keys] + 1] = func
end

local keyevents = {}
function keyevent.register_on_keypress(keys, func)
	keys, func = handle_keys(keys, func)
	add_func_to_callback_origins(func)
	if not keyevents[keys] then
		keyevents[keys] = {func}
		return
	end
	keyevents[keys][#keyevents[keys] + 1] = func
end
--------------------------------------------------------------------------------

-- use minetest registration fuctions:

local function on_step(dtime, player, old_keys, keys, player_name)
	if keys == old_keys then
		return
	end
	local diff = look_differences(keys, old_keys)
	for diff_shall, fs in pairs(keyevents_bits) do
		if is_different(diff_shall, diff) then
			minetest.run_callbacks(fs, -1, keys, old_keys, dtime, player_name)
		end
	end
	local keys_t = bits_to_table(keys)
	local old_keys_t = bits_to_table(old_keys)
	for diff_shall, fs in pairs(keyevents) do
		if is_different(diff_shall, diff) then
			minetest.run_callbacks(fs, -1, keys_t, old_keys_t, dtime, player_name)
		end
	end
	return keys
end

if INIT == "client" then -- csm
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

elseif INIT == "game" then -- ssm
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
