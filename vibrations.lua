-- Vibration system (MC 1.19 sculk mechanics) — unique work.
--
-- Neither game has a working vibration pipeline: both mcl_sculk mods have
-- the sensor/shrieker logic commented out. This module builds it:
--   emit(pos, frequency, player)  — vibration events from player actions
--   sensors within 8 nodes react (sound + visual pulse)
--   shriekers within 8 nodes scream (sound + param2 + warning message);
--   a second scream within 60 s summons the warden (if none is nearby)
--   listeners (e.g. the warden mob) can subscribe to hear vibrations
--
-- Frequencies (MC-ish): walking=1, jumping=4, digging=8, placing=8,
-- punching=16. Sneaking suppresses walking vibrations (MC parity).

mcl_mobs_addon = rawget(_G, "mcl_mobs_addon") or {}
mcl_mobs_addon.vibrations = mcl_mobs_addon.vibrations or {}
mcl_mobs_addon.shrieker_warnings = mcl_mobs_addon.shrieker_warnings or {}
local vib = mcl_mobs_addon.vibrations

vib.listeners = {}

-- forward declaration (vib.emit below calls it before its definition)
local activate_shrieker

function vib.register_listener(fn)
	table.insert(vib.listeners, fn)
end

-- MC vibration frequencies (approximation of the vanilla table)
vib.FREQ = {
	walk = 1,
	jump = 4,
	dig = 8,
	place = 8,
	punch = 16,
}

function vib.emit(pos, freq, player)
	if not pos then
		return
	end
	for _, fn in ipairs(vib.listeners) do
		pcall(fn, pos, freq, player)
	end

	-- sensors react within 8 nodes
	local sensor = minetest.find_node_near(pos, 8, { "mcl_mobs_addon:sculk_sensor" })
	if sensor then
		minetest.sound_play("mcl_sculk", { pos = sensor, gain = 0.7, max_hear_distance = 12 }, true)
		local n = minetest.get_node(sensor)
		n.param2 = 1
		minetest.set_node(sensor, n)
		minetest.after(1, function()
			local nn = minetest.get_node(sensor)
			if nn.name == "mcl_mobs_addon:sculk_sensor" and nn.param2 == 1 then
				nn.param2 = 0
				minetest.set_node(sensor, nn)
			end
		end)
		-- mesecons output: swap to the powered twin for a ~0.8s pulse
		-- (MC: sensors emit a redstone pulse on vibration; shriekers don't)
		if rawget(_G, "mesecon") and minetest.registered_nodes["mcl_mobs_addon:sculk_sensor_active"] then
			local cn = minetest.get_node(sensor)
			if cn.name == "mcl_mobs_addon:sculk_sensor" then
				minetest.set_node(sensor, { name = "mcl_mobs_addon:sculk_sensor_active" })
				minetest.after(0.8, function()
					local an = minetest.get_node(sensor)
					if an.name == "mcl_mobs_addon:sculk_sensor_active" then
						minetest.set_node(sensor, { name = "mcl_mobs_addon:sculk_sensor" })
					end
				end)
			end
		end
	end
	-- shriekers scream within 8 nodes
	local shrieker = minetest.find_node_near(pos, 8, { "mcl_mobs_addon:sculk_shrieker" })
	if shrieker then
		activate_shrieker(shrieker, player)
	end
end

-- ---------------------------------------------------------------------------
-- Shrieker: scream + warning level + warden summon
-- ---------------------------------------------------------------------------
local SHRIEK_COOLDOWN = 10
local WARNING_RESET = 60   -- seconds without a scream resets the warning level
local WARDEN_DIST = 32     -- don't summon if a warden is already this close

local function warn_player(player, msg)
	if player and player:is_player() then
		minetest.chat_send_player(player:get_player_name(), msg)
	end
end

activate_shrieker = function(pos, player)
	local now = minetest.get_us_time() / 1e6
	local key = minetest.pos_to_string(pos)
	-- warning state in a GLOBAL table (node meta is lost when the mapblock
	-- unloads — the param2 visual is unreliable for the same reason)
	local st = mcl_mobs_addon.shrieker_warnings[key]
	if not st then
		st = { last = 0, level = 0 }
		mcl_mobs_addon.shrieker_warnings[key] = st
	end

	-- cooldown by time; last==0 = first scream ever: never blocked
	if st.last > 0 and now - st.last < SHRIEK_COOLDOWN then
		return
	end
	st.last = now
	if st.last > 0 and now - st.last > WARNING_RESET then
		st.level = 0
	end
	st.level = st.level + 1

	local n = minetest.get_node(pos)
	if n.param2 ~= 1 then
		minetest.sound_play("mcl_sculk", { pos = pos, gain = 1.5, max_hear_distance = 16 }, true)
		n.param2 = 1
		minetest.set_node(pos, n)
		minetest.after(SHRIEK_COOLDOWN, function()
			local nn = minetest.get_node(pos)
			if nn.name == "mcl_mobs_addon:sculk_shrieker" then
				minetest.set_node(pos, { name = "mcl_mobs_addon:sculk_shrieker", param2 = 0 })
			end
		end)
	end

	-- warning level: 2nd scream within WARNING_RESET summons the warden
	if st.level >= 2 and minetest.registered_entities["mcl_mobs_addon:warden"] then
		-- summon the warden (MC: warning level 4; 2 is friendlier for play)
		local wardens = minetest.get_objects_inside_radius(pos, WARDEN_DIST)
		local exists = false
		for _, o in ipairs(wardens) do
			local le = o:get_luaentity()
			if le and le.name == "mcl_mobs_addon:warden" then
				exists = true
				break
			end
		end
		if not exists then
			-- find a spot 2-4 blocks above the shrieker
			for dy = 2, 4 do
				local p = vector.offset(pos, 0, dy, 0)
				if minetest.get_node(p).name == "air"
						and minetest.get_node(vector.offset(p, 0, 2, 0)).name == "air" then
					minetest.add_entity(p, "mcl_mobs_addon:warden")
					warn_player(player, "The darkness has awakened...")
					break
				end
			end
		end
		st.level = 0
	else
		warn_player(player, "The darkness is watching...")
	end
end

-- ---------------------------------------------------------------------------
-- Player action hooks -> vibrations
-- ---------------------------------------------------------------------------
local function hook_walkover(pos, node, player)
	if not player then
		return
	end
	if mcl_mobs_addon.is_spectator and mcl_mobs_addon.is_spectator(player) then
		return  -- spectators make no vibrations
	end
	local ctrl = player:get_player_control()
	if ctrl and ctrl.sneak then
		return  -- sneaking makes no vibrations (MC parity)
	end
	local v = player:get_velocity()
	if not v or (v.x == 0 and v.y == 0 and v.z == 0) then
		return
	end
	local freq = vib.FREQ.walk
	if v.y > 0.5 then
		freq = vib.FREQ.jump  -- jumping (or falling upward, close enough)
	end
	vib.emit(vector.offset(pos, 0, 1, 0), freq, player)
end

if minetest.get_modpath("walkover") then
	walkover.register_global(hook_walkover)
elseif minetest.get_modpath("mcl_walkover") then
	mcl_walkover.register_global(hook_walkover)
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	if digger and digger:is_player() then
		vib.emit(pos, vib.FREQ.dig, digger)
	end
end)

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if placer and placer:is_player() then
		vib.emit(pos, vib.FREQ.place, placer)
	end
end)

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	if puncher and puncher:is_player() then
		vib.emit(pos, vib.FREQ.punch, puncher)
	end
end)

minetest.log("action", "[mcl_mobs_addon] vibration system ready")
