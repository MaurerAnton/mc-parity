-- Spectator mode (MC parity, unique for both games): the spectator can fly
-- through blocks (noclip), is invisible, can't interact (no interact
-- privilege), takes no damage, and mobs don't react to them (vibrations
-- are not emitted). Toggle: /spec (privilege "spectator", granted to
-- admins by default). State persists per-player in meta (re-applied on join).

local S = minetest.get_translator("mc_parity")

minetest.register_privilege("spectator", {
	description = S("Can toggle spectator mode (/spec)"),
	give_to_singleplayer = true,
})

local function is_spectator(player)
	return player and player:is_player()
		and player:get_meta():get_string("mc_parity:spectator") == "true"
end
mc_parity.is_spectator = is_spectator

local function apply_spectator(player, on)
	local meta = player:get_meta()
	local name = player:get_player_name()
	if on then
		meta:set_string("mc_parity:spectator", "true")
		-- save privs for restore
		local privs = minetest.get_player_privs(name)
		meta:set_string("mc_parity:saved_privs", minetest.serialize(privs))
		-- interact off (can't dig/place/punch), fly + noclip on
		privs.interact = nil
		privs.fly = true
		privs.noclip = true
		minetest.set_player_privs(name, privs)
		-- invisible + small collision (noclip handles walls anyway)
		player:set_properties({
			visual_size = { x = 0.001, y = 0.001 },
			collisionbox = { 0, 0, 0, 0, 0, 0 },
			eye_height = 1.0,
		})
		player:set_physics_override({ speed = 2.0, jump = 1.0, gravity = 0.0 })
		minetest.chat_send_player(name, S("[mc_parity] Spectator mode ON (noclip, invisible, no damage)"))
	else
		meta:set_string("mc_parity:spectator", "")
		local saved = meta:get_string("mc_parity:saved_privs")
		local privs = saved ~= "" and minetest.deserialize(saved) or {}
		minetest.set_player_privs(name, privs)
		player:set_properties({
			visual_size = { x = 1, y = 1 },
			collisionbox = { -0.3, 0.0, -0.3, 0.3, 1.8, 0.3 },
			eye_height = 1.625,
		})
		player:set_physics_override({ speed = 1.0, jump = 1.0, gravity = 1.0 })
		minetest.chat_send_player(name, S("[mc_parity] Spectator mode OFF"))
	end
end

minetest.register_chatcommand("spec", {
	params = "",
	description = S("Toggle spectator mode"),
	privs = { spectator = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, S("Player not found")
		end
		apply_spectator(player, not is_spectator(player))
		return true
	end,
})

-- re-apply on join (state persists in meta)
minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	if meta:get_string("mc_parity:spectator") == "true" then
		apply_spectator(player, true)
	end
end)

-- no damage while spectating
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if is_spectator(player) and hp_change < 0 then
		return 0, true
	end
end, true)

minetest.log("action", "[mc_parity] spectator mode registered (/spec)")
