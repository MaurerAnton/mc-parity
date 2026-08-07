# MC Parity (mc_parity)

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

Place `mc_parity/` into the game's `mods/` directory (VoxeLibre:
`mods/mc_parity/`), or use it as a world modpack. Requires
`mcl_mobs` (bundled with both games). Enable in the world settings.

## Asset provenance

- Textures: **Pixel Perfection / Pixel Perfection Legacy** by XSSheep and
  Nova Wostra — CC BY-SA 4.0.
  Mirror used (raw file access):
  https://github.com/minetest-texture-packs/Pixel-Perfection-Legacy
  Original: https://www.planetminecraft.com/texture_pack/131pixel-perfection/
- Models: copied from VoxeLibre (GPLv3+ code / free media) and renamed with
  the `mc_parity_` prefix so they don't clash with the game's files:
  - https://git.minetest.land/VoxeLibre/VoxeLibre (mods/ENTITIES/mobs_mc/models/)
- All new files in this mod are prefixed `mc_parity_` to stay unique
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
          post-registration patch (helpers exposed on mc_parity.* so
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
        (new mc_parity:goat_horn item, Pixel-Perfection texture); horn
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
          home beach and lay eggs on sand (mc_parity:turtle_egg, PP
          texture); eggs hatch after 2-5 minutes into baby turtles
          (visual_size 0.6) that grow to full size after ~5 minutes
          (dropping a scute — MC parity).
          PITFALL: VoxeLibre NEVER calls def.on_activate for mobs (the
          final_def wraps it into mob_activate; def.on_activate is only
          used for projectiles) — hatchling state travels via an on_spawn
          registry instead of staticdata.
        - SCUTE + TURTLE SHELL (MC 1.13; missed in the original port):
          mc_parity:scute item (PP texture) + the turtle shell helmet
          via mcl_armor.register_set — mc_parity:helmet_turtle
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
          (mc_parity:nether_lava_source/_flowing) with liquid_viscosity
          = 1 and liquid_range = 7 — nether lava flows like water (MC).
          The nether's existing lava lakes are converted by an ABM: lava
          sitting on netherrack (overworld lava sits on stone — untouched).
          The conversion logic is extracted to
          mc_parity.convert_nether_lava for testability (ABMs don't
          run headless — no active blocks without players).
        - MC-ACCURATE FLUID SOLVER: NOT feasible as an addon — Luanti's
          liquid simulation runs natively in the engine
          (src/servermap.cpp transformLiquids); an addon cannot intercept
          or replace it. The only paths are an engine patch or a custom
          game that does not use the engine's liquid system. Documented
          here as the end of this roadmap item.
19. [x] MC 1.20.5/1.21 branch (mobs_121.lua) — unique (verified nowhere):
        - ARMADILLO: cuboid model (tools/gen_b3d.py) + painted textures
          (tools/paint_121.py — pure-Python PNG writer, no PIL); rolls
          into a ball when a player/hostile mob comes within 3 nodes
          (armor 100, can't move; unrolls after ~4s without threat);
          drops armadillo scute every 5-10 min; savanna spawn.
        - WOLF VARIANTS (1.20.5): the game's wolf gets a biome-based
          texture at spawn — Bettercraft's textures (GPLv3) with their
          biome map REMAPPED (their Grove/SnowyTaiga/OldGrowthPineTaiga
          don't exist here: both games use ColdTaiga/MegaTaiga/
          MegaSpruceTaiga; Mineclonia additionally has Grove). Verified:
          VL spawn biome -> pale wolf, Mineclonia -> spotted wolf.
        - WOLF ARMOR (1.21): 6 armadillo scute -> armor; right-click a
          tamed wolf to equip (overlay + ~60% damage reduction; drops on
          death). Tame/angry textures for variants: the game's own (TODO).
        - PITFALL: runtime entity patches must target
          minetest.registered_entities[name] (the whitelisted final_def
          class) — mutating mcl_mobs.registered_mobs (the original def)
          never reaches live entities. mcln_base_hp is exposed on the
          global table for dofile'd modules (armadillo would crash on
          Mineclonia otherwise: math.random(nil)).
20. [x] Polish pass (MC-accurate values):
        - WARDEN: melee 45 -> 30, sonic boom 25 -> 10 (MC; Bettercraft's
          were over-tuned).
        - GOAT: horns ONLY from charged rams (death drop removed, MC);
          charged rams always drop 1-2 horns.
        - SKELETON TRAP: MC parity — 4 skeleton horses WITH skeleton
          riders (jockeys) instead of 4 loose skeletons. Jockey API:
          VL = horse:jock_to(name, rel), Mineclonia =
          rider:jock_to_existing(horse, bone, rel, rot); attach offsets
          in NODE units (y=1.6 — Mineclonia's own trap value).
          PITFALL: lightning.strike needs a solid block below the strike
          point (cleared test areas silently no-op the strike).
        - TAMED WOLF VARIANTS: tamed variant wolves keep their fur +
          collar (wolf_<v>_tame.png); the dye handler still wins. Angry
          textures: the game never swaps to angry (VL dead asset) — TODO.
21. [x] Warden 2.0 + sculk sensor redstone (MC parity):
        - SONIC BOOM: ray-based shockwave that PASSES THROUGH WALLS
          (no line-of-sight check), aimed at the target (not the yaw —
          a fresh warden's yaw is arbitrary); replaces the vl_projectile
          variant (stopped at walls); identical on both games; damage
          via mcl_util.deal_damage (no knockback). PITFALL: the
          framework's deal_damage/damage_mob reduces luaentity.health
          but does NOT sync ObjectRef hp — verify with le.health.
        - DARKNESS: the addon registers the mcl_potions 'darkness'
          effect (icon painted); an angry warden re-applies it to its
          player target every 3s (5s). VL's skycolor darkens the sky;
          Mineclonia applies the effect (HUD) without the sky change.
        - HEARTBEAT: synthesized CC0 sounds (tools/gen_sounds.py:
          Python WAV + ffmpeg -> OGG) — heartbeat lub-dub + boom
          whoosh; played while agitated. No external media.
        - SCULK SENSOR -> REDSTONE: with mesecons installed the sensor
          swaps to an '_active' twin (receptor ON, all-dirs) for a
          ~0.8s pulse per vibration; shriekers stay redstone-free (MC).
          PITFALL: register_node in on_mods_loaded fails the engine's
          naming check (no mod context) — register the twin at load
          time (mesecons is an optional_depends, already loaded).
          Verified with a fake-mesecons worldmod stub.
        - mod.conf: optional_depends += mcl_potions, mesecons.
22. [x] Bogged + Breeze (MC 1.21 — last unique mobs):
        - BOGGED: moss-covered skeleton on the game's skeleton model +
          Bettercraft textures (GPLv3); does NOT burn in daylight (the
          skeleton's ignited_by_sunlight flag is omitted); shoots POISON
          arrows (mc_parity:poison_arrow — damage 4 + poison 8s,
          green [colorize on the game's arrow texture); drops slimeball
          + bones; swamps (Swampland/Swampland_shore/MangroveSwamp —
          verified in both games).
        - BREEZE: wind golem — cuboid model (gen_b3d.py: torso + head +
          4 FLOATING limbs) + painted white/blue texture; hops around;
          WIND CHARGE VOLLEY: a 3-ray fan (MC: 3-5 charges) with 1
          damage + HARD KNOCKBACK, through blocks; drops a breeze rod.
          MC: trial-chamber-only — spawn egg only (no structure here
          yet; trial chambers TODO).
        - PITFALL: the framework's "shoot" attack fires registered
          arrows via def.arrow automatically (the shulker pattern — no
          custom shoot_arrow needed); mob AI overrides set_velocity
          knockback on its next step (players keep the launch).
23. [x] Ported mobs from Mineclonia (GPLv3 — mobs_port.lua):
        - CREEPER (+charged), ENDERMAN, BLAZE, PUFFERFISH, RAVAGER,
          WANDERING TRADER (+ trader llama): closes the LAST ecosystem
          gaps — VoxeLibre lacked creeper/enderman/blaze/pufferfish/
          trader entirely; both lacked ravager.
        - Pipeline: tools/port_mcln.py (extract + id remap) +
          tools/assemble_port.py (de-Mineclonia) + tools/add_footer.py.
        - Adaptations: register_spawner -> dual-game
          register_monster_spawn (nether/end via biome lists); the
          MCLN-only targeting-rule API -> attack_player aggro; the
          raid/gwp/fish-movement machinery stripped; villager_base
          (a nil LOCAL) -> {}; the MCLN villager trade API guarded (the
          trader wanders with llamas; the trade UI is MCLN-only for
          now); spawn_class added (VL asserts); table.merge shim;
          mcln_base_hp for all 8 entities; biome lists verified against
          BOTH games (RoofedForest, Nether, *_ocean variants).
        - PITFALLS: mob_class.X(self, ...) must call
          mcl_mobs.mob_class.X(self, ...) — self:X(...) recurses when
          the def overrides X (stack overflow); the Mineclonia spawner
          blocks appear BEFORE register_egg (strip from the last
          register_mob, not the egg); is_canonical trader/llama
          spawners call register_spawner (nil on VL) — strip them.
24. [x] Bee + Drowned (the last two vanilla mobs — mobs 100%):
        - BEE: the games ship the full honey machinery (mcl_beehives +
          mcl_honey: nest/beehive with 5 honey levels, bottle/shears
          harvest, honey bottle/honeycomb/honey+comb blocks) but NO
          bee entity. Our bee: flies (fly=true), picks up pollen near
          the 16 flowers, grows crops (wheat/carrot/potato/beetroot
          stage advance), fills nests one level per visit
          (bee_nest -> bee_nest_5), stings when provoked (poison + the
          bee dies). Model: gen_b3d cuboid (body+head+2 wings),
          textures painted (stripes + translucent wings).
        - DROWNED: the game's zombie tinted teal (^[colorize),
          floats=1 (swims), spawns in the *_ocean biomes (neither game
          has a plain Ocean), drops fishing rods / nautilus shells /
          tridents (vl_tridents and mcl_tridents both guarded).
        - Verified headless BOTH games: bee flies, nest reaches _5,
          crops grow, both mobs have meshes.
25. [x] Trial Chambers (MC 1.21 structure — mobs_trial.lua):
        - TRIAL SPAWNER: node-timer block (the game's spawner pattern);
          spawns a wave scaled to the nearby player count (2 + 1/player,
          cap 8) from a weighted pool (zombie/skeleton/spider/stray/
          husk/slime + the breeze); the wave is tracked via the
          _mca_trial marker (globalstep counts survivors); cleared ->
          loot (wind charges, breeze rods, emeralds, diamonds + trial
          key) -> 30 min cooldown.
        - VAULT: per-player loot container opened with the trial key.
        - trial key + wind charge items (painted textures).
        - build_trial_chambers: tuff/copper labyrinth — central chamber
          with copper pillars + spawner, 4 corridors with lava traps,
          4 vault rooms; generated deep underground (y -45..-15) in all
          overworld biomes via mcl_structures.
        - PITFALLS: get_mapgen_object is mapgen-thread-only — the
          builders pcall-fallback to direct set_node (works everywhere);
          pos_to_string must be minetest.pos_to_string (not a global on
          5.16); corridor directions read d[3] for the z axis — a
          {0,0,1} vector's z lives at index 3 (d[2] = y = 0 makes every
          corridor hit the centre).
26. [x] Trail Ruins (MC 1.20 structure — mobs_ruins.lua):
        - SUSPICIOUS SAND/GRAVEL: hidden loot in the meta, brushed out
          (8 strokes + particles) -> the block becomes plain
          sand/gravel.
        - BRUSH tool (64 uses); 9 pottery sherds + decorated pot
          (craft: 4 sherds); RELIC music disc via
          mcl_jukebox.register_record (plays a game track, CC BY-SA).
        - build_trail_ruins: small buried mud-brick ruin with gravel,
          packed-mud columns and 4 pre-filled suspicious blocks;
          generated in taiga/snowy biomes.
        - Verified headless BOTH games: registrations, both structures
          build, brushing drops the loot.
27. [x] Feature selection menu (config.lua):
        - On the FIRST JOIN a formspec menu appears (and /mca-config
          reopens it): the user picks which MC-version feature sets are
          active — version groups (1.21 / 1.20 / 1.19 / 1.17 / 1.15 /
          1.14 / 1.13 / classic pre-1.13 VL ports / addon extras) plus
          per-feature overrides ("features from 1.20, not from 1.19,
          only part of 1.13").
        - Stored per world (mod storage); changes apply after a server
          restart (registrations happen at load).
        - Gating: every registration wrapped in
          mc_parity.feature_enabled(id) — version group AND not
          individually disabled; ~35 features tagged in the FEATURES
          table (tools/wrap_gates.py wrapped the module sections).
        - PITFALLS: config.lua loads FIRST (dofile before the helpers)
          so it creates the mc_parity global itself; the port
          footer's mcln_base_hp stays OUTSIDE the trader wrap (it
          patches all 8 entities — safe no-op for unregistered names);
          the mod storage file is a JSON object of strings.
        - Verified headless: default = everything; a seeded storage
          disabling 1.19+1.15+bogged removes warden/allay/frog/bee/
          bogged while fox/camel/breeze/trial/turtle/phantom stay.
28. [x] Pre-1.13 closers (legacy.lua):
        - WOODLAND MANSION (MC 1.11): a 27x27 two-storey dark-oak
          mansion — log pillars, central hall + stairs, library
          (bookshelves), dining (red carpet), wheat farm, lava room,
          the 1.19 ALLAY CAGE (trapped allay), bedroom, obsidian room,
          the arena (vindicators + evoker), 6 loot chests; RoofedForest.
        - END CITY TOWERS (MC 1.9) for VoxeLibre (it only had the
          ships; Mineclonia has small_end_city): 9x9 purpur tower —
          3 floors, corner pillars, spire, 3 chests, 2 shulkers; End
          biomes.
        - DISCS: cat, stal, ward, 11 — the 4 pre-1.13 discs absent
          from both games' jukebox (tracks reuse the games' CC BY-SA
          recordings; labels painted).
        - PITFALLS: the VL fence node is mcl_fences:dark_oak_fence
          (the register helper appends the _fence suffix — the woods
          table id is NOT the node name); Mineclonia's dark oak lives
          in mcl_trees (dual-game pick at load).
        - Verified headless BOTH games: mansion (wall + 6 chests),
          tower (purpur), 4 discs, 6 mobs spawned inside.
29. [x] Last pre-1.13 items (legacy_items.lua — pre-1.13 now ~100%):
        - LEAD (1.6): 3 string + slimeball; right-click a mob to attach,
          a fence post to tether; globalstep pulls the mob back inside
          the 10-block range (or follows the owner).
        - DRAGON HEAD (1.9): a placeable nodebox trophy (mcl_heads'
          API prepends its own prefix — can't be called from another
          mod's load context — our own node instead).
        - SHULKER BOXES (1.11): 17 colors; 27-slot inventory; digging
          drops the box WITH its contents (serialized into the item
          meta, restored on place). Craft: 2 shulker shells + 2 chests.
        - TIPPED/SPECTRAL ARROWS (1.9): 6 effects + spectral; the games'
          bows fire ANY item with the ammo_bow group — the items carry
          _arrow_image + a per-effect entity copying the game's arrow
          class with the effect injected on hit (VL: wrapped
          on_collide_with_entity; Mineclonia: their _extra_hit_func).
          Crafts: 8 arrows + lingering potion -> 8 tipped; 1 arrow +
          glowstone dust -> 2 spectral.
        - PITFALLS: the engine's after_dig_node passes oldmetadata =
          meta:to_table() (NOT a MetadataRef) and .inventory.main holds
          ItemStack userdata (empty slots are empty ItemStacks — use
          :is_empty(), not ~= ""); the dropped item's contents travel
          inside the item string, not the entity fields.
        - Verified headless BOTH games: items/entities registered,
          ammo_bow set, the box keeps its diamond through dig/place.
30. [x] 100% closure (port_items.lua + mobs_final.lua — the full 1.0-1.21
        audit's last 15 gaps):
        - PORTED (GPLv3 from Mineclonia, for VL — tools/port_items.py):
          conduit, dripstone (blocks + pointed growth; the MCLN-levelgen
          worldgen is not portable), candles (5 colors + cake), powder
          snow (freezing), echo shard, mace (+ heavy core). Chain
          ported the OTHER way (VL -> Mineclonia).
        - FINAL CLOSERS (mobs_final.lua): 5 coral blocks + fans + dead,
          moss block + carpet, tuff bricks/polished/chiseled, copper
          bulb (mesecons twin-swap light), crafter (3x3 + timer craft),
          recovery compass (death location hook + echo-shard craft),
          oak hanging sign (formspec text), pitcher plant + torchflower,
          bubble columns (bubbly/whirly liquids + player push).
        - PITFALLS: no node_sound_copper_defaults (use stone);
          register_globalstep_slow is MCLN-only — its fallback must
          emulate the per-player loop (the standard globalstep passes
          no player — dtime as the player crashes); mcl_dyes (MCLN) vs
          mcl_dye (VL); palette_index_to_color MCLN-only; Lua 5.1
          rejects a parenthesized call at statement start; the mcl_tools
          global is MCLN-only (store the mace state on our table).
        - Verified headless BOTH games: all 15 features registered, the
          crafter crafts (2 wood -> pressure plate), coral + bubble
          nodes place.

## Model pipeline (WIP mobs)

New mobs need .b3d models in the game's cuboid style with walk/idle/run
animation frames (see the existing models/ for frame conventions).

- Formats overview: https://docs.luanti.org/for-creators/models/
- Blender:        https://docs.luanti.org/for-creators/models/using-blender/
- Blockbench:     https://docs.luanti.org/for-creators/models/using-blockbench/
- Texture bases: Pixel Perfection / REFI (CC BY-SA 4.0), see Asset provenance.
- After export: place as `models/mc_parity_<mob>.b3d` and uncomment the
  registration template in init.lua (WIP section).

## Pitfalls (verified with luanti 5.16.1 + VoxeLibre 0.92.1, headless)

- **Mineclonia spawn API**: `mcl_mobs.spawn_setup` still EXISTS in Mineclonia
  but only as a deprecated shim — it logs "Calling spawn_setup() is
  deprecated" and the mob "will not spawn naturally". Always prefer
  `mcl_mobs.register_spawner` when present (feature-detect order matters:
  register_spawner first, spawn_setup second). Biome tags: `#is_taiga`,
  `#is_jungle`, ... — there is NO `#is_desert` tag, use the `"Desert"` name.
- **Entity id prefix**: `mcl_mobs.register_mob` requires the id to start with
  the ADDON's own mod name (`mc_parity:fox`), NOT `mobs_mc:fox` — the
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
  then grep the log for `[mc_parity]` banner / `ModError` / `ERROR`.
- Runtime check: the banner log line sits AFTER all register calls in
  init.lua — its presence in the log proves every registration succeeded.

## License

- Code: GPL-3.0-only (mod.conf)
- Media: CC BY-SA 4.0 (Pixel Perfection textures) / game models per
  VoxeLibre licensing
