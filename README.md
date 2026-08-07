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
11. [ ] Deep dark biome + ancient city (unique — nowhere)
12. [x] Shulker upgrade (shulker_upgrade.lua) — MC-parity face attachment +
        the "900-degree spin" quirk: VoxeLibre's static shulker now rotates
        to all 6 faces with an animated spin on re-attach; Mineclonia's
        instant rotation becomes an animated spin. Works on both games
        (feature-detected), patches the game's own mobs_mc:shulker at
        runtime. Verified headless on both.

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
