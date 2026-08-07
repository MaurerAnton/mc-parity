# mcl_mobs_addon

Extra Minecraft-style mobs for **VoxeLibre** (and eventually Mineclonia),
implemented as a standalone addon mod. Works on top of the game's existing
`mcl_mobs` / `mobs_mc` framework.

## Status (2026-08-07)

| Mob            | Model base (from VoxeLibre)      | Texture (Pixel-Perfection-Legacy)       | Spawn        | Sounds |
|----------------|----------------------------------|-----------------------------------------|--------------|--------|
| fox            | mobs_mc_wolf.b3d                 | fox.png (+ snow/sleep variants shipped) | Taiga family | in-game*|
|                |                                  | hunts chickens/rabbits (MC parity)     |              |        |
| panda          | mobs_mc_polarbear.b3d            | panda.png (+ 6 personality variants)   | BambooJungle | in-game*|
| camel          | mobs_mc_llama.b3d                | camel.png                               | Desert       | in-game*|
|                |                                  | rideable (llama driver pattern)        |              |        |
| skeleton_horse | mobs_mc_horse.b3d                | horse_skeleton.png                      | trap only    | in-game*|
|                |                                  | lightning skeleton trap (VL)           |              |        |
| goat           | **procedural b3d** (tools/gen_b3d.py, no Blender needed!) | goat.png (Pixel-Perfection) | ExtremeHills/#is_mountain | TODO   |
| bundle (item)  | — (craftitem)                     | bundle.png                              | —            | —      |
| allay          | **new Blender model needed**     | allay.png                               | —            | TODO   |
| frog           | **new Blender model needed**     | frog_{temperate,cold,warm}.png          | —            | TODO   |
| warden         | **new Blender model needed**     | warden.png (+ glow/ears layers)         | —            | TODO   |
| phantom        | **new Blender model needed**     | phantom.png (+ eyes)                    | —            | TODO   |
| turtle         | **new Blender model needed**     | big_sea_turtle.png                      | —            | TODO   |
| sniffer        | **new Blender model needed**     | sniffer.png                             | —            | TODO   |
| goat           | **new Blender model needed**     | goat.png                                | —            | TODO   |

## Install

Place `mcl_mobs_addon/` into the game's `mods/` directory (VoxeLibre:
`mods/mcl_mobs_addon/`), or use it as a world modpack. Requires
`mcl_mobs` (bundled with both games). Enable in the world settings.

## Asset provenance

- Textures: **Pixel Perfection / Pixel Perfection Legacy** by XSSheep and
  Nova Wostra — CC BY-SA 4.0.
  Mirror used (raw file access):
  https://github.com/minetest-texture-packs/Pixel-Perfection-Legacy
  Original: https://www.planetminecraft.com/texture_pack/131pixel-perfection/
- Models: copied from VoxeLibre (GPLv3+ code / free media) and renamed with
  the `mcl_mobs_addon_` prefix so they don't clash with the game's files:
  - https://git.minetest.land/VoxeLibre/VoxeLibre (mods/ENTITIES/mobs_mc/models/)
- All new files in this mod are prefixed `mcl_mobs_addon_` to stay unique
  across the game's global texture/model namespace.

## Work plan (in order)

1. [x] 4 retexture mobs registered (fox, panda, camel, skeleton_horse)
2. [x] Sounds for all 4 mobs — in-game free sounds (CC BY-SA); *CC0 external
        sounds remain optional (fox uses wolf barks as placeholder)
3. [x] Fox: chicken/rabbit hunting behavior (MC parity)
4. [x] Panda personalities (variant textures already shipped)
5. [x] Skeleton horse: lightning skeleton trap (VL; 4 skeletons, hostile)
6. [x] Camel riding (llama driver pattern; MC 2-seat = TODO)
7. [x] GOAT — first mob with a procedurally generated .b3d (tools/gen_b3d.py,
        no Blender needed) — unique: no goat exists in VL/Mineclonia/
        Bettercraft/ContentDB
8. [x] BUNDLE (MC 1.17) — contents travel in item metadata; craft 6 leather
        + 2 string; v1: view + take out (insert = TODO)
9. [ ] Import from Bettercraft (GPLv3): warden/allay/frog+tadpole/phantom/
        sniffer/turtle mobs + real panda/camel models + bubble column +
        daylight detector + trial spawners/mace + froglight
10. [ ] Warden AI: vibration sensing + anger + sonic boom (VL sculk sensor
        is a stub — the vibration system must be built; genuinely unique)
11. [x] Deep Dark + Ancient City (deepdark.lua) — the FULL MC 1.19 package:
        - sculk sensor + shrieker NODES registered (absent in BOTH games —
          commented out in both mcl_sculk mods) with the game textures
        - DeepDark biome + sculk patch generation PORTED to VoxeLibre
          (Mineclonia already has biome+patches; ours is checked in
          on_mods_loaded so it never duplicates)
        - sensor/shrieker scatter ores in the deep dark (both games)
        - FULL Ancient City structure (Lua place_func builder, no .mts):
          central hall, 4 pillars + central monument, soul lanterns on
          chains, sculk floor, corridors to 4 side rooms with loot chests,
          sensors + shriekers — Mineclonia has only the mini "hermitage"
        - functional shriekers: walking near one screams + warns (both
          games' shrieker logic is inert)
        - place_func signature pitfall documented in-code: mcl_structures
          calls it as (pos, def, pr, blockseed)
12. [x] Shulker upgrade (shulker_upgrade.lua) — MC-parity face attachment +
        the "900-degree spin" quirk: VoxeLibre's static shulker now rotates
        to all 6 faces with an animated spin on re-attach; Mineclonia's
        instant rotation becomes an animated spin. Works on both games
        (feature-detected), patches the game's own mobs_mc:shulker at
        runtime. Verified headless on both.
13. [x] Glass chests (glass_chests.lua) — MC mod parity (cpw/ironchest
        "Crystal Chest" is the canonical glass chest; MC vanilla has none;
        NOTHING exists for Luanti — checked ContentDB + both trees +
        Bettercraft + GitHub code search):
        - glass chest: transparent (see-through), 27 slots. VL: full variant
          with lid entity (manual registration — see pitfall below);
          Mineclonia: static nodebox variant (their entity helpers are
          local). Craft: 8 glass + chest.
        - glass ender chest: semi-transparent, shares the player's ender
          inventory. VL: with lid entity; Mineclonia: static. Craft:
          8 glass + eye of ender.
        - PITFALL: Luanti 5.16 blocks registering mcl_chests:* node ids from
          other mods ("Name does not follow naming conventions") — the
          game's own mcl_chests.register_chest API is unusable from addons;
          register manually under your own prefix and use the PUBLIC
          mcl_chests.create_entity / player_chest_open helpers.
14. [x] Warden + vibration system (vibrations.lua, warden.lua) — MC 1.19:
        - warden mob imported from Bettercraft (GPLv3; there it is plain
          melee with a DEAD sonic-boom arrow) — our prefix, model+texture,
          emerge animation, drops sculk catalyst
        - vibration system (unique — both games' sculk logic is commented
          out): emit(pos, freq, player) event bus + player-action hooks
          (walking/jumping via walkover, digging, placing, punching;
          sneaking is silent), sensors react within 8 nodes (sound+pulse),
          shriekers scream within 8 nodes
        - shrieker -> warden: warning level in a GLOBAL table (node meta is
          lost on block unload); 2nd scream within 60s summons the warden
          (MC parity: no natural spawn — shrieker-only + creative egg)
        - warden HEARING: the blind warden reacts to vibrations within 24
          nodes (targets the player or investigates the source; 60s decay)
        - SONIC BOOM: ranged attack at 4-15 blocks (vl_projectile on VL;
          Bettercraft's arrow was dead code — wired up; Mineclonia melee v1)
        - PITFALL: Mineclonia's mob activate reads hp_min/hp_max from the
          DEF BASE (math.random(self.hp_min,...)) while VoxeLibre wants them
          in initial_properties — register with initial_properties, then add
          def.hp_min/hp_max post-registration on Mineclonia
          (mcl_mobs.register_spawner is the Mineclonia marker)
15. [x] Bettercraft import batch 1 (mobs_import.lua) — frog, turtle,
        phantom, sniffer + REAL panda/camel models (replacing the
        polar-bear/llama retextures). Bettercraft = Mineclonia fork,
        GPLv3 + free media (LEGAL.md verified):
        - FROG: biome textures (cold/temperate/warm via the game's
          _mcl_biome_type), hops, eats tiny slimes/magma cubes and drops
          froglight from magma cubes; spawns Swampland/MangroveSwamp
        - TURTLE: slow beach walker, swims, seagrass-breedable on
          Mineclonia (feed_tame feature-detected; egg-laying TODO — needs
          the nest block); spawns StoneBeach
        - PHANTOM: full Bettercraft AI — circles 18-20 blocks above the
          nearest non-creative player, random dives (punch fleshy 6),
          retreats upward 2s when damaged, burns in daylight (light>12);
          drops phantom membrane; egg-only spawn (the spawn systems have
          no time-of-day filter — MC night-only spawning is TODO)
        - SNIFFER: peaceful relic hunter, egg-only for now
        - PANDA: real model + Bettercraft animations (stand 0-25, walk/
          punch 30-70); personality textures stay ours
        - CAMEL: real model + animations (stand 1-40, walk 70-100, run
          130-146); our riding logic kept
        - FIXED latent Mineclonia bug: fox/panda/camel/goat/skeleton_horse
          had hp only in initial_properties -> math.random(nil) crash at
          spawn on Mineclonia — all base mobs now get the mcln_base_hp
          post-registration patch (helpers exposed on mcl_mobs_addon.* so
          dofile'd modules can call them — dofile chunks see only globals)
        - NOT imported: allay (Mineclonia-only motion_step/run_ai hooks —
          needs a VoxeLibre-compatible movement rewrite; TODO)
16. [x] Allay (allay.lua) — Bettercraft import with a cross-game movement
        rewrite. Bettercraft's motion_step/run_ai are Mineclonia-native;
        both games call do_custom (returning false skips the framework's
        own step logic — VL mcl_mobs/api.lua:403, Mineclonia api.lua:705):
        - Mineclonia: motion_step/run_ai hooks (native); VoxeLibre: do_custom
        - the movement + item-drop logic are LOCAL functions (forward
          declared) captured by the hook closures — NOT def fields, because
          VoxeLibre's register_mob builds a WHITELISTED final_def and drops
          unknown fields (a def field _motion was silently nil -> crash)
        - delivery AI: give an item -> collects matching drops within 32
          nodes -> returns them to you; persistent state; creative egg only
        - PITFALL: pass a Lua function as a table FIELD and it survives;
          store it as a custom field and VoxeLibre drops it.
17. [x] Goat polish (init.lua): MC ramming — provoked goats wind up 0.7s,
        charge (damage fleshy 2 + knockback), charged rams drop goat horns
        (new mcl_mobs_addon:goat_horn item, Pixel-Perfection texture); horn
        drop on death; llama/cow sounds (the game's own CC BY-SA media).
        Skeleton trap: confirmed working on BOTH games — Mineclonia ships a
        COMPAT "lightning" shim whose metatable resolves lightning.* to
        mcl_lightning (same register_on_strike API as VL).
        Phantom night spawn: globalstep spawns phantoms at night near
        non-creative players (no 3-sleepless-nights tracking yet — TODO).
        Camel: second seat (MC parity) — passenger attaches behind the
        driver, both dismount together.
18. [x] TODO-tail + far items:
        - TURTLE EGGS (MC parity): breeding turtles walk back to their
          home beach and lay eggs on sand (mcl_mobs_addon:turtle_egg, PP
          texture); eggs hatch after 2-5 minutes into baby turtles
          (visual_size 0.6) that grow to full size after ~5 minutes
          (dropping a scute — MC parity).
          PITFALL: VoxeLibre NEVER calls def.on_activate for mobs (the
          final_def wraps it into mob_activate; def.on_activate is only
          used for projectiles) — hatchling state travels via an on_spawn
          registry instead of staticdata.
        - SCUTE + TURTLE SHELL (MC 1.13; missed in the original port):
          mcl_mobs_addon:scute item (PP texture) + the turtle shell helmet
          via mcl_armor.register_set — mcl_mobs_addon:helmet_turtle
          (2 armor points, durability 275, craft = 5 scute — MC recipe);
          wearing it grants water breathing while the head is underwater.
          PITFALLS: register_set names items element.name..'_'..def.name
          ('helmet_turtle', the helmet_iron convention — NOT turtle_helmet);
          the armor head slot is index 2 (mcl_armor.elements.head.index),
          not 1. Elytra: BOTH games already have them (mcl_armor) — not
          missed.
        - PHANTOM 3-NIGHTS: bed nodes are runtime-patched (wrap the
          original on_rightclick; the player is marked when is_in_bed());
          a noon tracker resets/increments each player's sleepless count;
          phantoms spawn only at night for players with 3+ sleepless days
          (MC parity). The patch covers any mcl_beds:* node.
        - GOAT HORN INSTRUMENT: the horn plays a random note from the
          game's own mesecons_noteblock sounds (CC BY-SA game media).
        - CC0 goat sounds: searched OpenGameArt — only a CC-BY variant
          with a broken attachment; the goat keeps the game's llama/cow
          sounds (legal). Real CC0 samples: TODO.
        - CAMEL SEATS: tuned to the REAL camel model geometry (parsed the
          b3d vertex bounds: camel = 24.7 model units tall vs llama 21.7)
          — driver on the hump (y=22), passenger behind (y=19, z=6);
          in-game visual tuning still recommended.
        - SPECTATOR MODE (/spec, privilege "spectator"): noclip + fly +
          invisible (visual_size ~0), no interact privilege (can't
          dig/place/punch), no damage (on_player_hpchange), mobs ignore
          spectators (vibrations not emitted, phantoms don't target or
          spawn for them); state persists in player meta, re-applied on
          join.
        - NETHER LAVA (MC parity, unique): a new liquid pair
          (mcl_mobs_addon:nether_lava_source/_flowing) with liquid_viscosity
          = 1 and liquid_range = 7 — nether lava flows like water (MC).
          The nether's existing lava lakes are converted by an ABM: lava
          sitting on netherrack (overworld lava sits on stone — untouched).
          The conversion logic is extracted to
          mcl_mobs_addon.convert_nether_lava for testability (ABMs don't
          run headless — no active blocks without players).
        - MC-ACCURATE FLUID SOLVER: NOT feasible as an addon — Luanti's
          liquid simulation runs natively in the engine
          (src/servermap.cpp transformLiquids); an addon cannot intercept
          or replace it. The only paths are an engine patch or a custom
          game that does not use the engine's liquid system. Documented
          here as the end of this roadmap item.

## Model pipeline (WIP mobs)

New mobs need .b3d models in the game's cuboid style with walk/idle/run
animation frames (see the existing models/ for frame conventions).

- Formats overview: https://docs.luanti.org/for-creators/models/
- Blender:        https://docs.luanti.org/for-creators/models/using-blender/
- Blockbench:     https://docs.luanti.org/for-creators/models/using-blockbench/
- Texture bases: Pixel Perfection / REFI (CC BY-SA 4.0), see Asset provenance.
- After export: place as `models/mcl_mobs_addon_<mob>.b3d` and uncomment the
  registration template in init.lua (WIP section).

## Pitfalls (verified with luanti 5.16.1 + VoxeLibre 0.92.1, headless)

- **Mineclonia spawn API**: `mcl_mobs.spawn_setup` still EXISTS in Mineclonia
  but only as a deprecated shim — it logs "Calling spawn_setup() is
  deprecated" and the mob "will not spawn naturally". Always prefer
  `mcl_mobs.register_spawner` when present (feature-detect order matters:
  register_spawner first, spawn_setup second). Biome tags: `#is_taiga`,
  `#is_jungle`, ... — there is NO `#is_desert` tag, use the `"Desert"` name.
- **Entity id prefix**: `mcl_mobs.register_mob` requires the id to start with
  the ADDON's own mod name (`mcl_mobs_addon:fox`), NOT `mobs_mc:fox` — the
  `mobs_mc:` prefix is only valid inside the game's own `mobs_mc` mod.
  Violation → ModError: "Name does not follow naming conventions".
  References to game mobs inside fields (`specific_attack`, `follow`, drops)
  are plain strings and keep the `mobs_mc:` prefix.
- **User path**: luanti 5.16 on Arch uses `~/.minetest` (games/, worlds/),
  not `~/.local/share/luanti`.
- **Loading**: placing the addon in `<game>/mods/` loads reliably; world-mods
  in `worlddir/mods/` need matching `load_mod_<name> = true` in world.mt.
- **Headless test recipe**:
  `timeout 90 luanti --server --world <path> --logfile /tmp/t.log`
  then grep the log for `[mcl_mobs_addon]` banner / `ModError` / `ERROR`.
- Runtime check: the banner log line sits AFTER all register calls in
  init.lua — its presence in the log proves every registration succeeded.

## License

- Code: GPL-3.0-or-later (mod.conf)
- Media: CC BY-SA 4.0 (Pixel Perfection textures) / game models per
  VoxeLibre licensing
