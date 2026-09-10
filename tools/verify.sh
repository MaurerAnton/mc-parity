#!/bin/bash
# ---------------------------------------------------------------------------
# mc_parity verification — runs on every push via GitHub Actions and
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
LUAC_BIN="$(command -v luac || command -v luac5.1 || command -v luac5.4 || true)"
if [ -z "$LUAC_BIN" ]; then echo "SKIP: luac not found"; else
LUA_FILES=""
for f in "$SRC"/*.lua; do LUA_FILES="$LUA_FILES $f"; done
if "$LUAC_BIN" -p $LUA_FILES; then PASS "all modules"; else BAD "syntax"; fi
fi

# ---- 2. code markers ----
echo "== [2/5] code markers =="
grep -q 'register_mob ("mc_parity:creeper"' "$SRC/mobs_port.lua" && PASS "creeper" || BAD "creeper"
grep -q 'register_mob ("mc_parity:enderman"' "$SRC/mobs_port.lua" && PASS "enderman" || BAD "enderman"
grep -q 'register_mob ("mc_parity:blaze"' "$SRC/mobs_port.lua" && PASS "blaze" || BAD "blaze"
grep -q 'register_mob ("mc_parity:pufferfish"' "$SRC/mobs_port.lua" && PASS "pufferfish" || BAD "pufferfish"
grep -q 'register_mob ("mc_parity:ravager"' "$SRC/mobs_port.lua" && PASS "ravager" || BAD "ravager"
grep -q 'register_mob ("mc_parity:wandering_trader"' "$SRC/mobs_port.lua" && PASS "wandering trader" || BAD "trader"
grep -q 'register_mob("mc_parity:bee"' "$SRC/mobs_bee.lua" && PASS "bee" || BAD "bee"
grep -q 'register_mob("mc_parity:drowned"' "$SRC/mobs_121.lua" && PASS "drowned" || BAD "drowned"
grep -q 'register_mob("mc_parity:bogged"' "$SRC/mobs_121.lua" && PASS "bogged" || BAD "bogged"
grep -q 'register_mob("mc_parity:breeze"' "$SRC/mobs_121.lua" && PASS "breeze" || BAD "breeze"
grep -q 'register_node("mc_parity:trial_spawner"' "$SRC/mobs_trial.lua" && PASS "trial spawner" || BAD "trial spawner"
grep -q 'register_node("mc_parity:vault"' "$SRC/mobs_trial.lua" && PASS "vault" || BAD "vault"
grep -q 'register_node("mc_parity:suspicious_sand"' "$SRC/mobs_ruins.lua" && PASS "suspicious sand" || BAD "suspicious sand"
grep -q 'register_node("mc_parity:suspicious_gravel"' "$SRC/mobs_ruins.lua" && PASS "suspicious gravel" || BAD "suspicious gravel"
grep -q 'register_tool("mc_parity:brush"' "$SRC/mobs_ruins.lua" && PASS "brush" || BAD "brush"
grep -q 'title = "Relic"' "$SRC/mobs_ruins.lua" && PASS "relic disc" || BAD "relic disc"
grep -q 'build_woodland_mansion' "$SRC/legacy.lua" && PASS "mansion builder" || BAD "mansion"
grep -q 'build_end_city_tower' "$SRC/legacy.lua" && PASS "end city builder" || BAD "end city"
grep -q 'title = "Cat"' "$SRC/legacy.lua" && PASS "cat disc" || BAD "cat disc"

# ---- 3. in-engine (needs luanti + the games; skipped when unavailable) ----
echo "== [3/5] in-engine checks =="
ENGINE_BIN="$(command -v luantiserver || command -v luanti-server || command -v luanti || command -v minetest || true)"
if [ -z "$ENGINE_BIN" ]; then
	echo "SKIP: luanti/minetest not installed (luac checks only)"
else
	echo "engine: $ENGINE_BIN"
	if ! "$ENGINE_BIN" --version >/dev/null 2>&1; then BAD "engine not runnable"; fi
	if [ ! -d "$VL_GAME" ]; then
		echo "cloning VoxeLibre ($VL_TAG)…"
		git clone -q --depth 1 --branch "$VL_TAG" "$VL_REPO" "$VL_GAME" || { BAD "vl clone"; }
	fi
	if [ ! -d "$MCLN_GAME" ]; then
		echo "cloning Mineclonia ($MCLN_TAG)…"
		git clone -q --depth 1 --branch "$MCLN_TAG" "$MCLN_REPO" "$MCLN_GAME" || { BAD "mcln clone"; }
	fi

	# the engine only finds games under its user path: point HOME at our
	# sandbox (still never touches the real ~/.minetest) and link the
	# cloned games in as mineclone2 / mineclonia.
	export HOME="$WORK/fakehome"
	mkdir -p "$HOME/.minetest/games"
	ln -sfn "$VL_GAME" "$HOME/.minetest/games/mineclone2"
	ln -sfn "$MCLN_GAME" "$HOME/.minetest/games/mineclonia"

	run_world() {  # $1 = world dir, $2 = gameid, $3 = log file, $4 = label
		# dedicated server binaries (luantiserver/…) run headless by
		# default; the combined client binaries need the --server flag
		# (5.16 errors on Unknown command-line parameter "--server").
		local flags=()
		case "$(basename "$ENGINE_BIN")" in
			luantiserver|luanti-server|minetestserver) ;;
			*) flags=(--server) ;;
		esac
		timeout 90 "$ENGINE_BIN" "${flags[@]}" --world "$1" --gameid "$2" \
			--logfile "$3" >"$WORK/$4.out.log" 2>"$WORK/$4.err.log"
		if [ ! -f "$3" ]; then
			BAD "$4: no log (server never started)"
			echo "--- $4 stdout (head) ---"; head -20 "$WORK/$4.out.log" 2>/dev/null
			echo "--- $4 stderr (head) ---"; head -20 "$WORK/$4.err.log" 2>/dev/null
			return
		fi
		if grep -q "loaded=8" "$3"; then PASS "8 mobs spawn ($4)"; else BAD "$4 spawn: $(grep -o 'loaded=.*' "$3" | head -1)"; fi
		if grep -q "ModError\|ERROR\[Main\]" "$3"; then
			BAD "$4 errors"
			grep "ModError\|ERROR\[Main\]" "$3" | head -5
		else PASS "$4 clean"; fi
	}

	write_probe() {  # $1 = world dir
		local probe="$1/worldmods/mcl_addon_probe"
		mkdir -p "$probe"
		cat > "$probe/mod.conf" <<'EOF'
name = mcl_addon_probe
description = verify probe (tools/verify.sh)
depends = mcl_core
optional_depends = mc_parity, mobs_mc
EOF
		cat > "$probe/init.lua" <<'EOF'
minetest.register_on_mods_loaded(function()
	minetest.after(3, function()
		local c = { x = 0, y = 0, z = 0 }
		for dx = -6, 6 do for dy = -6, 8 do for dz = -6, 6 do
			minetest.set_node(vector.add(c, { x = dx, y = dy, z = dz }), { name = "air" })
		end end end
		local IS_MCLN = mcl_mobs and mcl_mobs.register_spawner ~= nil
		local mobs = {
			"mc_parity:creeper", "mc_parity:enderman",
			"mc_parity:blaze", "mc_parity:pufferfish",
			"mc_parity:ravager", "mc_parity:wandering_trader",
			"mc_parity:bee", "mc_parity:drowned",
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
	}

	mkdir -p "$VL_WORLD/worldmods" "$MCLN_WORLD/worldmods"
	cp -r "$SRC" "$VL_GAME/mods/mc_parity"
	cp -r "$SRC" "$MCLN_GAME/mods/mc_parity"

	# the in-engine probe (spawns every unique mob, checks meshes)
	write_probe "$VL_WORLD"
	write_probe "$MCLN_WORLD"

	echo "-- VoxeLibre --"
	run_world "$VL_WORLD" mineclone2 "$WORK/vl.log" "VL"

	echo "-- Mineclonia --"
	run_world "$MCLN_WORLD" mineclonia "$WORK/mcln.log" "MCLN"
fi

# ---- 4. git state ----
echo "== [4/5] git state =="
cd "$SRC" && [ -z "$(git status --porcelain)" ] && PASS "tree clean" || BAD "dirty: $(git status --porcelain | head -3)"

echo "== [5/5] RESULT: $([ $FAIL -eq 0 ] && echo ALL PASS || echo FAILURES) =="
rm -rf "$WORK"
exit $FAIL
