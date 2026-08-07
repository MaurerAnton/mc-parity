-- Shulker upgrade: MC-parity attachment + the famous "900-degree spin".
--
-- Minecraft: when a shulker re-attaches to a block face, its shell rotates to
-- the new orientation through a long interpolation path — visibly spinning
-- several full turns (up to 900°, a well-known vanilla quirk).
--
-- VoxeLibre:  mobs_mc:shulker is a static noyaw mob (yaw forced to 0), no
--             face attachment, no rotation at all.
-- Mineclonia: shulker rotates to all 6 faces but INSTANTLY (set_bone_override
--             with absolute=true) — the spin is missing there too.
--
-- This module patches the shulker entity at runtime (after all mods load):
--   VL:       face detection -> object:set_rotation with animated spin
--   Mineclonia: attach_to_face -> animated bone rotation with spin
-- The spin: rotation interpolates from the old face to the new one while
-- adding 2.5 extra turns (900 deg) around the Y axis over ~0.8 s.
-- Feature-detect based, so it works on whichever game is installed.
-- Media/code: GPLv3 (Mineclonia attachment table adapted from their shulker.lua).

local SPIN_DURATION = 0.8   -- seconds
local SPIN_TURNS_DEG = 900  -- 2.5 full turns, the MC quirk

-- VL: object:set_rotation (radians). Convention: right-handed EXTRINSIC
-- Z-X-Y (roll first, pitch, yaw last) — NOT the bone-override convention.
-- Values map model-up (+Y, the lid) onto the opening direction per face:
local ROT_RAD = {
	north = vector.new(math.pi * 3 / 2, 0, 0),  -- open -Z: pitch -90°
	south = vector.new(math.pi / 2, 0, 0),      -- open +Z: pitch +90°
	west  = vector.new(0, 0, math.pi / 2),      -- open -X: roll +90°
	east  = vector.new(0, 0, math.pi * 3 / 2),  -- open +X: roll -90°
	up    = vector.new(0, 0, 0),
	down  = vector.new(0, 0, math.pi),          -- open -Y: roll 180°
}

-- Mineclonia: set_bone_position takes degrees.
local ROT_DEG = {
	north = vector.new(90, 0, 180),
	west  = vector.new(0, 0, 90),
	south = vector.new(270, 0, 0),
	east  = vector.new(0, 0, 270),
	up    = vector.new(0, 0, 0),
	down  = vector.new(0, 0, 180),
}

-- direction from the shulker to the solid block it is attached to
local FACE_DIR = {
	north = vector.new(0, 0, -1),
	south = vector.new(0, 0, 1),
	west  = vector.new(-1, 0, 0),
	east  = vector.new(1, 0, 0),
	up    = vector.new(0, 1, 0),
	down  = vector.new(0, -1, 0),
}

local function solid_at(pos)
	return minetest.get_item_group(minetest.get_node(pos).name, "solid") > 0
end

local function find_face(pos)
	for face, dir in pairs(FACE_DIR) do
		if solid_at(vector.add(pos, dir)) then
			return face
		end
	end
	return nil
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

-- ---------------------------------------------------------------------------
-- VL patch: the shulker entity is a plain mcl_mobs mob (noyaw). We replace
-- do_custom: keep armor/teleport behavior but drive object:set_rotation with
-- face attachment + animated spin.
-- ---------------------------------------------------------------------------
local function patch_voxelibre()
	local ent = minetest.registered_entities["mobs_mc:shulker"]
	if not ent or not ent.do_custom then
		return
	end

	ent.do_custom = function(self, dtime)
		local pos = self.object:get_pos()
		-- face: keep current if still attached, else find a new one
		local face = self._mca_face
		if face then
			local dir = FACE_DIR[face]
			if not (dir and solid_at(vector.add(pos, dir))) then
				face = nil
			end
		end
		if not face then
			face = find_face(pos)
		end

		-- start a spin when the face changes (not on first attach)
		if face ~= self._mca_face then
			local from = self._mca_rot or ROT_RAD[face] or vector.new(0, 0, 0)
			local to = face and ROT_RAD[face] or vector.new(0, 0, 0)
			self._mca_face = face
			if self._mca_rot then
				self._mca_spin = { t = 0, dur = SPIN_DURATION, from = from, to = to }
			else
				self._mca_rot = to  -- first attach: no spin, place directly
			end
		end

		local rot
		if self._mca_spin then
			local s = self._mca_spin
			s.t = s.t + dtime
			local p = math.min(s.t / s.dur, 1)
			rot = vector.new(
				lerp(s.from.x, s.to.x, p),
				lerp(s.from.y, s.to.y, p) + math.rad(SPIN_TURNS_DEG) * p,
				lerp(s.from.z, s.to.z, p)
			)
			if s.t >= s.dur then
				rot = s.to
				self._mca_spin = nil
			end
		else
			rot = self._mca_rot or vector.new(0, 0, 0)
			if face and not self._mca_spin then
				rot = ROT_RAD[face]
			end
		end
		self._mca_rot = rot
		self.object:set_rotation(rot)

		-- original do_custom logic, minus the forced set_yaw(0) (would fight
		-- the rotation). The original teleports away when no solid face is
		-- adjacent (check_spot fails) — keep that:
		if self.state == "attack" then
			self:set_animation("run")
			self.armor = 0
		elseif self.state == "stand" then
			self.armor = 20
		elseif self.state == "walk" or self.state == "run" then
			self.armor = 0
		end
		self.path.way = false
		self.look_at_players = false
		if not face and self.teleport then
			self:teleport(nil)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Mineclonia patch: attach_to_face sets the bone override instantly; we make
-- it animate (spin) instead. The attachment parameters table is a local in
-- their shulker.lua, so we duplicate the rotation values (ROT_DEG above).
-- ---------------------------------------------------------------------------
local function patch_mineclonia()
	local ent = minetest.registered_entities["mobs_mc:shulker"]
	if not ent or not ent.attach_to_face then
		return
	end
	local orig_custom = ent.do_custom

	ent.attach_to_face = function(self, facedir)
		-- replicate the tail of the original (cbox reset etc.) but skip the
		-- instant bone override — the spin animation applies it instead.
		self._face = facedir
		local first = self._mca_face == nil
		if first then
			-- initial attach (spawn/activate): place directly, no spin
			self._mca_face = facedir
			self._mca_rot = ROT_DEG[facedir]
		else
			self._mca_from = self._mca_rot or ROT_DEG[self._mca_face] or ROT_DEG.up
			self._mca_face = facedir
			self._mca_spin = { t = 0, dur = SPIN_DURATION, from = self._mca_from,
				to = ROT_DEG[facedir] }
			self._mca_rot = nil  -- animated per-step now
		end
		if self.extend_cbox_to then
			self:extend_cbox_to(0)
		end
		self._cbox_retract_delay = 0
		self._cbox_extension = 0
		self._cbox_delta = 0
		self._cbox_animation = 0
		self._cbox_duration = 0
		self._look_target = nil
	end

	ent.do_custom = function(self, dtime)
		if self._mca_spin then
			local s = self._mca_spin
			s.t = s.t + dtime
			local p = math.min(s.t / s.dur, 1)
			local deg = vector.new(
				lerp(s.from.x, s.to.x, p),
				lerp(s.from.y, s.to.y, p) + SPIN_TURNS_DEG * p,
				lerp(s.from.z, s.to.z, p)
			)
			if self.object.set_bone_position then
				self.object:set_bone_position("root", vector.new(0, 0, 0), deg)
			end
			if s.t >= s.dur then
				self._mca_spin = nil
				self._mca_rot = s.to
				-- final exact override (absolute), same semantics as original
				if self.object.set_bone_override then
					self.object:set_bone_override("root", {
						rotation = { vec = vector.apply(s.to, math.rad), absolute = true },
					})
				end
			end
		end
		if orig_custom then
			orig_custom(self, dtime)
		end
	end
end

minetest.register_on_mods_loaded(function()
	if not mcl_mobs or not mcl_mobs.registered_mobs then
		return
	end
	local ent = minetest.registered_entities["mobs_mc:shulker"]
	if not ent then
		return
	end
	if ent.attach_to_face then
		patch_mineclonia()
		minetest.log("action", "[mc_parity] shulker upgrade: Mineclonia (spin)")
	else
		patch_voxelibre()
		minetest.log("action", "[mc_parity] shulker upgrade: VoxeLibre (face+spin)")
	end
end)
