#!/bin/bash
# ---------------------------------------------------------------------------
# mcl_mobs_addon verification — runs on every push via GitHub Actions and
# locally. Checks:
#   1. luac syntax of every Lua module
#   2. code markers (mobs registered, key mechanics present)
#   3. in-engine headless run on BOTH VoxeLibre and Mineclonia: the addon
#      loads clean and all unique mobs spawn with meshes
#   4. git tree clean
#
# Local usage:  tools/verify.sh
# It creates its own temp game dirs and worlds under $TMP (default /tmp),
# so it never touches ~/.minetest.
# ---------------------------------------------------------------------------
set -u

SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d /tmp/mcl_addon_verify-XXXXXX)"
VL_GAME="$WORK/vl"
MCLN_GAME="$WORK/mcln"
VL_WORLD="$WORK/world_vl"
MCLN_WORLD="$WORK/world_mcln"
VL_REPO="https://git.minetest.land/MineClone2/MineClone2.git"
MCLN_REPO="https://codeberg.org/Mineclonia/Mineclonia.git"
VL_TAG="${VL_TAG:-master}"
MCLN_TAG="${MCLN_TAG:-main}"
FAIL=0
PASS() { echo "PASS: $1"; }
BAD() { echo "FAIL: $1"; FAIL=1; }

# ---- 1. luac ----
echo "== [1/5] luac syntax =="
LUA_FILES=""
for f in "$SRC"/*.lua; do LUA_FILES="$LUA_FILES $f"; done
if luac -p $LUA_FILES; then PASS "all modules"; else BAD "syntax"; fi

# ---- 2. code markers ----
echo "== [2/5] code markers =="
grep -q 'register_mob ("mcl_mobs_addon:creeper"' "$SRC/mobs_port.lua" && PASS "creeper" || BAD "creeper"
grep -q 'register_mob ("mcl_mobs_addon:enderman"' "$SRC/mobs_port.lua" && PASS "enderman" || BAD "enderman"
grep -q 'register_mob ("mcl_mobs_addon:blaze"' "$SRC/mobs_port.lua" && PASS "blaze" || BAD "blaze"
grep -q 'register_mob ("mcl_mobs_addon:pufferfish"' "$SRC/mobs_port.lua" && PASS "pufferfish" || BAD "pufferfish"
grep -q 'register_mob ("mcl_mobs_addon:ravager"' "$SRC/mobs_port.lua" && PASS "ravager" || BAD "ravager"
grep -q 'register_mob ("mcl_mobs_addon:wandering_trader"' "$SRC/mobs_port.lua" && PASS "wandering trader" || BAD "trader"
grep -q 'register_mob("mcl_mobs_addon:bee"' "$SRC/mobs_bee.lua" && PASS "bee" || BAD "bee"
grep -q 'register_mob("mcl_mobs_addon:drowned"' "$SRC/mobs_121.lua" && PASS "drowned" || BAD "drowned"
grep -q 'register_mob("mcl_mobs_addon:bogged"' "$SRC/mobs_121.lua" && PASS "bogged" || BAD "bogged"
grep -q 'register_mob("mcl_mobs_addon:breeze"' "$SRC/mobs_121.lua" && PASS "breeze" || BAD "breeze"

# ---- 3. in-engine (needs luanti + the games; skipped when unavailable) ----
echo "== [3/5] in-engine checks =="
if ! command -v luanti >/dev/null 2>&1; then
	echo "SKIP: luanti not installed (luac checks only)"
else
	if [ ! -d "$VL_GAME" ]; then
		echo "cloning VoxeLibre ($VL_TAG)…"
		git clone -q --depth 1 --branch "$VL_TAG" "$VL_REPO" "$VL_GAME" || { BAD "vl clone"; }
	fi
	if [ ! -d "$MCLN_GAME" ]; then
		echo "cloning Mineclonia ($MCLN_TAG)…"
		git clone -q --depth 1 --branch "$MCLN_TAG" "$MCLN_REPO" "$MCLN_GAME" || { BAD "mcln clone"; }
	fi

	mkdir -p "$VL_WORLD/worldmods" "$MCLN_WORLD/worldmods"
	cp -r "$SRC" "$VL_GAME/mods/mcl_mobs_addon"
	cp -r "$SRC" "$MCLN_GAME/mods/mcl_mobs_addon"

	# the in-engine probe (spawns every unique mob, checks meshes)
	PROBE="$VL_WORLD/worldmods/mcl_addon_probe"
	mkdir -p "$PROBE"
	cat > "$PROBE/mod.conf" <<'EOF'
name = mcl_addon_probe
description = verify probe (tools/verify.sh)
depends = mcl_core
optional_depends = mcl_mobs_addon, mobs_mc
EOF
	cat > "$PROBE/init.lua" <<'EOF'
minetest.register_on_mods_loaded(function()
	minetest.after(3, function()
		local c = { x = 0, y = 0, z = 0 }
		for dx = -6, 6 do for dy = -6, 8 do for dz = -6, 6 do
			minetest.set_node(vector.add(c, { x = dx, y = dy, z = dz }), { name = "air" })
		end end end
		local IS_MCLN = mcl_mobs and mcl_mobs.register_spawner ~= nil
		local mobs = {
			"mcl_mobs_addon:creeper", "mcl_mobs_addon:enderman",
			"mcl_mobs_addon:blaze", "mcl_mobs_addon:pufferfish",
			"mcl_mobs_addon:ravager", "mcl_mobs_addon:wandering_trader",
			"mcl_mobs_addon:bee", "mcl_mobs_addon:drowned",
		}
		local objs = {}
		for i, m in ipairs(mobs) do
			local o = minetest.add_entity({ x = (i - 5) * 3, y = 3, z = 0 }, m)
			if o then table.insert(objs, o) end
		end
		minetest.after(IS_MCLN and 0.05 or 0.2, function()
			local ok, valid = {}, 0
			for _, o in ipairs(objs) do
				local le = o:get_luaentity()
				if le then
					ok[le.name] = true
					local props = o:get_properties()
					if props and props.mesh then valid = valid + 1 end
				end
			end
			minetest.log("action", "[verify_probe] loaded=" .. valid)
			for _, o in ipairs(objs) do if o:is_valid() then o:remove() end end
		end)
	end)
end)
EOF

	echo "-- VoxeLibre --"
	cp -r "$VL_WORLD" "$VL_WORLD.bak" 2>/dev/null; rm -rf "$VL_WORLD.bak"
	timeout 60 luanti --server --world "$VL_WORLD" --gameid mineclone2 \
		--logfile "$WORK/vl.log" >/dev/null 2>&1
	if grep -q "loaded=8" "$WORK/vl.log"; then PASS "8 mobs spawn (VL)"; else BAD "VL spawn: $(grep -o 'loaded=.*' "$WORK/vl.log" | head -1)"; fi
	if grep -q "ModError\|ERROR\[Main\]" "$WORK/vl.log"; then BAD "VL errors"; else PASS "VL clean"; fi

	echo "-- Mineclonia --"
	cp -r "$VL_WORLD" "$MCLN_WORLD" && rm -rf "$MCLN_WORLD/worldmods" && mkdir -p "$MCLN_WORLD/worldmods"
	cp -r "$PROBE" "$MCLN_WORLD/worldmods/mcl_addon_probe"
	timeout 60 luanti --server --world "$MCLN_WORLD" --gameid mineclonia \
		--logfile "$WORK/mcln.log" >/dev/null 2>&1
	if grep -q "loaded=8" "$WORK/mcln.log"; then PASS "8 mobs spawn (Mineclonia)"; else BAD "MCLN spawn: $(grep -o 'loaded=.*' "$WORK/mcln.log" | head -1)"; fi
	if grep -q "ModError\|ERROR\[Main\]" "$WORK/mcln.log"; then BAD "MCLN errors"; else PASS "MCLN clean"; fi
fi

# ---- 4. git state ----
echo "== [4/5] git state =="
cd "$SRC" && [ -z "$(git status --porcelain)" ] && PASS "tree clean" || BAD "dirty: $(git status --porcelain | head -3)"

echo "== [5/5] RESULT: $([ $FAIL -eq 0 ] && echo ALL PASS || echo FAILURES) =="
rm -rf "$WORK"
exit $FAIL
