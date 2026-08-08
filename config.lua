-- ---------------------------------------------------------------------------
-- FEATURE CONFIGURATION (menu + gating)
-- The user chooses which MC-version feature sets (and which individual
-- features) are active. On the first join a menu formspec is shown; it can
-- be reopened with /mca-config. Changes apply on the next server start
-- (registrations happen at load time).
-- ---------------------------------------------------------------------------

mc_parity = {}  -- loaded first, before init.lua uses it (no `or {}` — that read trips Luanti's strict undeclared-global warning)

local S = minetest.get_translator("mc_parity")

-- feature registry: id -> { version group, human description }
local FEATURES = {
	-- 1.21 (Tricky Trials)
	armadillo       = { version = "1.21", desc = "Armadillo + scute" },
	wolf_armor      = { version = "1.21", desc = "Wolf armor" },
	bogged          = { version = "1.21", desc = "Bogged (swamp skeleton)" },
	breeze          = { version = "1.21", desc = "Breeze + wind volley" },
	trial_chambers  = { version = "1.21", desc = "Trial chambers + spawner + vault" },
	-- 1.20 (Trails & Tales)
	sniffer         = { version = "1.20", desc = "Sniffer" },
	camel           = { version = "1.20", desc = "Camel + seats" },
	wolf_variants   = { version = "1.20", desc = "Wolf variants (9 biomes)" },
	trail_ruins     = { version = "1.20", desc = "Trail ruins + archaeology (brush, sherds, Relic)" },
	-- 1.19 (The Wild)
	warden          = { version = "1.19", desc = "Warden + sonic boom + darkness" },
	allay           = { version = "1.19", desc = "Allay" },
	frog            = { version = "1.19", desc = "Frog" },
	deep_dark       = { version = "1.19", desc = "Deep dark biome + ancient city" },
	sculk           = { version = "1.19", desc = "Sculk sensor/shrieker + vibrations + redstone" },
	-- 1.17 (Caves & Cliffs)
	goat            = { version = "1.17", desc = "Goat + horn" },
	bundle          = { version = "1.17", desc = "Bundle" },
	-- 1.15 (Buzzy Bees)
	bee             = { version = "1.15", desc = "Bee + honey filling + pollination" },
	-- 1.14 (Village & Pillage)
	fox             = { version = "1.14", desc = "Fox" },
	panda           = { version = "1.14", desc = "Panda" },
	-- 1.13 (Update Aquatic)
	turtle          = { version = "1.13", desc = "Turtle + eggs + scute + shell" },
	phantom         = { version = "1.13", desc = "Phantom (3 sleepless nights)" },
	drowned         = { version = "1.13", desc = "Drowned" },
	pufferfish      = { version = "1.13", desc = "Pufferfish (3 sizes)" },
	-- classic (pre-1.13 — the VoxeLibre gaps, ported from Mineclonia)
	creeper         = { version = "classic", desc = "Creeper (+charged) — VL port" },
	enderman        = { version = "classic", desc = "Enderman — VL port" },
	blaze           = { version = "classic", desc = "Blaze — VL port" },
	wandering_trader = { version = "classic", desc = "Wandering trader + llamas — VL port" },
	ravager         = { version = "classic", desc = "Ravager" },
	skeleton_horse  = { version = "classic", desc = "Skeleton horse + trap" },
	-- extras (addon-only, no MC version)
	glass_chests    = { version = "extras", desc = "Glass chests (see-through)" },
	spectator       = { version = "extras", desc = "Spectator mode (/spec)" },
	nether_lava     = { version = "extras", desc = "Fast-flowing nether lava" },
	shulker_upgrade = { version = "extras", desc = "Shulker: 6 faces + spin" },
}

-- version groups, ordered for the menu
local VERSION_ORDER = { "1.21", "1.20", "1.19", "1.17", "1.15", "1.14", "1.13", "classic", "extras" }
local VERSION_LABEL = {
	["1.21"] = "1.21 (Tricky Trials)",
	["1.20"] = "1.20 (Trails & Tales)",
	["1.19"] = "1.19 (The Wild)",
	["1.17"] = "1.17 (Caves & Cliffs)",
	["1.15"] = "1.15 (Buzzy Bees)",
	["1.14"] = "1.14 (Village & Pillage)",
	["1.13"] = "1.13 (Update Aquatic)",
	classic = "Classic (pre-1.13 VL ports)",
	extras  = "Addon extras (not MC-versioned)",
}

-- ---------------------------------------------------------------- config --
local storage = minetest.get_mod_storage()
local config = { versions = {}, disabled = {} }  -- disabled: set of feature ids

local function load_config()
	local ok, data = pcall(minetest.deserialize, storage:get_string("config"))
	if ok and type(data) == "table" then
		config = data
		config.versions = config.versions or {}
		config.disabled = config.disabled or {}
	end
end
load_config()

local function save_config()
	storage:set_string("config", minetest.serialize(config))
	storage:set_string("configured", "true")
end

-- version group enabled?
function mc_parity.version_enabled(v)
	if config.versions[v] == false then return false end
	return true
end

-- feature enabled? (version group AND not individually disabled)
function mc_parity.feature_enabled(id)
	local f = FEATURES[id]
	if not f then return true end  -- unknown features stay enabled
	if config.disabled[id] == true then return false end
	if config.versions[f.version] == false then return false end
	return true
end

function mc_parity.feature_desc(id)
	return FEATURES[id] and FEATURES[id].desc or id
end

-- ---------------------------------------------------------------- menu ----
local function open_menu(player)
	local name = player:get_player_name()
	local ver = {}
	for _, v in ipairs(VERSION_ORDER) do
		ver[v] = config.versions[v] ~= false
	end
	local feats = {}
	for id in pairs(FEATURES) do
		feats[id] = config.disabled[id] ~= true
	end
	local formspec = "formspec_version[6]"
		.. "size[9,10]"
		.. "label[0.3,0.2;" .. minetest.formspec_escape(
			S("mc_parity feature selection")) .. "]"
		.. "label[0.3,0.7;" .. minetest.formspec_escape(
			S("Choose which Minecraft-version features are active.")) .. "]"
		.. "label[0.3,1.1;" .. minetest.formspec_escape(
			S("Changes apply after a server restart.")) .. "]"
		-- scrollable list (formspec v6 scroll_container; the game's
		-- settings/creative forms use the same pattern). scroll_factor 0.01
		-- keeps the scrollbar value in fine-grained units (0.01 per unit).
		.. "scroll_container[0.3,1.5;8.4,7.2;_mcparity_scroll;vertical;0.01]"
	local y = 0
	for _, v in ipairs(VERSION_ORDER) do
		formspec = formspec .. string.format(
			"checkbox[0,%g;ver_%s;%s;%s]", y, v, VERSION_LABEL[v], ver[v] and "true" or "false")
		y = y + 0.4
	end
	y = y + 0.3
	formspec = formspec .. "label[0," .. y .. ";" .. minetest.formspec_escape(
		S("Individual features (fine-grained overrides):")) .. "]"
	y = y + 0.4
	for _, v in ipairs(VERSION_ORDER) do
		for id, f in pairs(FEATURES) do
			if f.version == v then
				local state = feats[id] and "true" or "false"
				local label = string.format("  [%s] %s", VERSION_LABEL[v]:match("^([0-9.]+)") or v, f.desc)
				formspec = formspec .. string.format("checkbox[0,%g;feat_%s;%s;%s]",
					y, id, minetest.formspec_escape(label), state)
				y = y + 0.4
			end
		end
	end
	local view_h = 7.2
	local scroll_max = math.ceil(math.max(0, y - view_h) / 0.01)
	local thumb_size = math.floor((view_h / y) * scroll_max)
	formspec = formspec
		.. "scroll_container_end[]"
		.. string.format("scrollbaroptions[smallstep=50;largestep=150;max=%d;thumbsize=%d]",
			scroll_max, thumb_size)
		.. "scrollbar[8.7,1.5;0.3,7.2;vertical;_mcparity_scroll;0]"
		.. string.format("button[1.0,9.0;3,0.8;save;%s]", S("Save"))
		.. string.format("button[5.0,9.0;3,0.8;reset;%s]", S("Reset to all enabled"))
	minetest.show_formspec(name, "mc_parity:config", formspec)
end

-- track any interaction with our menu (open/clicks/ESC all arrive here),
-- so the auto-show knows the player actually saw it
local menu_seen = false

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "mc_parity:config" then return end
	menu_seen = true
	if fields.reset then
		config.versions = {}
		config.disabled = {}
		save_config()
		open_menu(player)
		return
	end
	if fields.save then
		for _, v in ipairs(VERSION_ORDER) do
			local f = fields["ver_" .. v]
			config.versions[v] = (f == "true")
		end
		for id in pairs(FEATURES) do
			local f = fields["feat_" .. id]
			config.disabled[id] = (f == "false")
		end
		save_config()
		minetest.chat_send_player(player:get_player_name(),
			S("Configuration saved. Restart the server for the changes to take effect."))
		-- close the menu so the "saved" state is obvious (and the
		-- auto-shown first-join menu doesn't linger)
		minetest.close_formspec(player:get_player_name(), "mc_parity:config")
	end
end)

minetest.register_chatcommand("mca-config", {
	description = S("Open the mc_parity feature selection menu"),
	privs = { server = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then open_menu(player) end
		return true
	end,
})

-- show the menu once on the first join (when nothing has been configured).
-- Retry once after 6 s if the player never saw it (the first send can be
-- dropped while the client is still loading the world).
if storage:get_string("configured") ~= "true" then
	minetest.register_on_joinplayer(function(player)
		if storage:get_string("configured") ~= "true" then
			storage:set_string("configured", "true")  -- show once
			local pname = player:get_player_name()
			local function show()
				local p = minetest.get_player_by_name(pname)
				if p then open_menu(p) end
			end
			minetest.after(1, function()
				if menu_seen then return end
				show()
				minetest.after(6, function()
					if not menu_seen then show() end
				end)
			end)
		end
	end)
end

minetest.log("action", "[mc_parity] feature config loaded ("
	.. tostring(storage:get_string("configured") == "true") .. ")")
