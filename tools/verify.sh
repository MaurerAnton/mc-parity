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
grep -q 'register_mob("mc_parity:tadpole"' "$SRC/mobs_tadpole.lua" && PASS "tadpole" || BAD "tadpole"
grep -q 'register_node("mc_parity:frogspawn"' "$SRC/mobs_tadpole.lua" && PASS "frogspawn" || BAD "frogspawn"
grep -q 'register_craftitem("mc_parity:bucket_tadpole"' "$SRC/mobs_tadpole.lua" && PASS "tadpole bucket" || BAD "tadpole bucket"
grep -q 'mc_parity:vl_trader' "$SRC/mobs_port.lua" && PASS "VL trade UI" || BAD "VL trade UI"
grep -q 'function mc_parity.leash_attach' "$SRC/legacy_items.lua" && PASS "lead API" || BAD "lead API"
grep -q 'leash_attach (llama.object' "$SRC/mobs_port.lua" && PASS "llama leash" || BAD "llama leash"
grep -q 'wind_charge 4' "$SRC/mobs_trial.lua" && PASS "wind charge craft" || BAD "wind charge craft"
grep -q 'mc_parity:brush' "$SRC/mobs_121.lua" && PASS "brushable armadillo" || BAD "brushable armadillo"
grep -q 'disc_fragment_5' "$SRC/deepdark.lua" && PASS "disc 5" || BAD "disc 5"
grep -q '_mca_dupe' "$SRC/allay.lua" && PASS "allay duplication" || BAD "allay duplication"
grep -q 'meta:set_string("description"' "$SRC/init.lua" && PASS "bundle tooltip" || BAD "bundle tooltip"
grep -q '_mca_sniff_t' "$SRC/mobs_import.lua" && PASS "sniffer sniffing" || BAD "sniffer sniffing"
grep -q 'register_mob("mc_parity:creaking"' "$SRC/mobs_pale.lua" && PASS "creaking" || BAD "creaking"
grep -q 'register_node(HEART' "$SRC/mobs_pale.lua" && grep -q 'creaking_heart = "mc_parity:creaking_heart"\|HEART = "mc_parity:creaking_heart"' "$SRC/mobs_pale.lua" && PASS "creaking heart" || BAD "creaking heart"
grep -q 'register_craftitem("mc_parity:resin_clump"' "$SRC/mobs_pale.lua" && PASS "resin" || BAD "resin"
grep -q 'eyeblossom_open' "$SRC/mobs_pale.lua" && PASS "eyeblossom" || BAD "eyeblossom"
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
	clone_game() {  # $1 = repo, $2 = branch, $3 = dir, $4 = label
		local i
		for i in 1 2 3; do
			if [ -d "$3/.git" ]; then return 0; fi
			echo "cloning $4 ($2, try $i)…"
			if git clone -q --depth 1 --branch "$2" "$1" "$3" 2>"$WORK/$4.clone.err"; then
				return 0
			fi
			head -3 "$WORK/$4.clone.err" 2>/dev/null
			rm -rf "$3"  # never keep a partial clone
			sleep 15
		done
		BAD "$4 clone"
		return 1
	}
	clone_game "$VL_REPO" "$VL_TAG" "$VL_GAME" "VoxeLibre"
	clone_game "$MCLN_REPO" "$MCLN_TAG" "$MCLN_GAME" "Mineclonia"

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
		# the engine must have found the game (a failed clone used to
		# fall back to the other game and fake a spawn pass)
		if grep -q "Game \".*\" not found" "$3"; then
			BAD "$4: game not found"
			grep "Game \".*\" not found" "$3" | head -2
			return
		fi
		if grep -q "\[verify_probe\] loaded=23/23" "$3"; then
			PASS "23 mobs spawn ($4)"
		else
			BAD "$4 spawn: $(grep -o '\[verify_probe\] loaded=.*' "$3" | head -1)"
		fi
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
		for dx = -30, 30 do for dy = -6, 8 do for dz = -6, 6 do
			minetest.set_node(vector.add(c, { x = dx, y = dy, z = dz }), { name = "air" })
		end end end
		local IS_MCLN = mcl_mobs and mcl_mobs.register_spawner ~= nil
		local mobs = {
			-- the five original mobs
			"mc_parity:fox", "mc_parity:panda", "mc_parity:camel",
			"mc_parity:skeleton_horse", "mc_parity:goat",
			-- ported classics
			"mc_parity:creeper", "mc_parity:enderman", "mc_parity:blaze",
			"mc_parity:pufferfish", "mc_parity:ravager",
			"mc_parity:wandering_trader",
			-- 1.13-1.19 imports
			"mc_parity:phantom", "mc_parity:turtle", "mc_parity:frog",
			"mc_parity:sniffer", "mc_parity:allay", "mc_parity:tadpole",
			-- 1.15-1.21 uniques
			"mc_parity:bee", "mc_parity:drowned", "mc_parity:bogged",
			"mc_parity:armadillo", "mc_parity:breeze", "mc_parity:creaking",
		}
		local objs = {}
		local half = math.ceil(#mobs / 2)
		for i, m in ipairs(mobs) do
			local o = minetest.add_entity({ x = (i - half) * 2, y = 3, z = 0 }, m)
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
			minetest.log("action", "[verify_probe] loaded=" .. valid .. "/" .. #mobs)
			for _, o in ipairs(objs) do if o:is_valid() then o:remove() end end
		end)
	end)
end)
EOF
	}

	have_vl=0; have_mcln=0
	[ -d "$VL_GAME/.git" ] && have_vl=1
	[ -d "$MCLN_GAME/.git" ] && have_mcln=1

	mkdir -p "$VL_WORLD/worldmods" "$MCLN_WORLD/worldmods"
	if [ "$have_vl" = 1 ]; then
		cp -r "$SRC" "$VL_GAME/mods/mc_parity"
		write_probe "$VL_WORLD"
		echo "-- VoxeLibre --"
		run_world "$VL_WORLD" mineclone2 "$WORK/vl.log" "VL"
	else
		BAD "VL: clone unavailable — in-engine stage skipped"
	fi
	if [ "$have_mcln" = 1 ]; then
		cp -r "$SRC" "$MCLN_GAME/mods/mc_parity"
		write_probe "$MCLN_WORLD"
		echo "-- Mineclonia --"
		run_world "$MCLN_WORLD" mineclonia "$WORK/mcln.log" "MCLN"
	else
		BAD "MCLN: clone unavailable — in-engine stage skipped"
	fi
fi

# ---- 4. git state ----
echo "== [4/5] git state =="
cd "$SRC" && [ -z "$(git status --porcelain)" ] && PASS "tree clean" || BAD "dirty: $(git status --porcelain | head -3)"

echo "== [5/5] RESULT: $([ $FAIL -eq 0 ] && echo ALL PASS || echo FAILURES) =="
rm -rf "$WORK"
exit $FAIL
