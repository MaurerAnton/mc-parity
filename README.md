# mcl_mobs_addon

Extra Minecraft-style mobs for **VoxeLibre** (and eventually Mineclonia),
implemented as a standalone addon mod. Works on top of the game's existing
`mcl_mobs` / `mobs_mc` framework.

## Status (2026-08-07)

| Mob            | Model base (from VoxeLibre)      | Texture (Pixel-Perfection-Legacy)       | Spawn        | Sounds |
|----------------|----------------------------------|-----------------------------------------|--------------|--------|
| fox            | mobs_mc_wolf.b3d                 | fox.png (+ snow/sleep variants shipped) | Taiga family | TODO   |
| panda          | mobs_mc_polarbear.b3d            | panda.png (+ 6 personality variants)    | BambooJungle | TODO   |
| camel          | mobs_mc_llama.b3d                | camel.png                               | Desert       | TODO   |
| skeleton_horse | mobs_mc_horse.b3d                | horse_skeleton.png                      | trap only    | TODO   |
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
2. [ ] Sounds for all mobs (CC0 sources: freesound.org, Kenney.nl)
3. [ ] Fox: chicken hunting behavior (MC parity)
4. [ ] Panda personalities (variant textures already shipped)
5. [ ] Skeleton horse: skeleton trap (lightning conversion, riders)
6. [ ] Camel riding (copy driver logic from llama.lua)
7. [ ] Blender models for allay, frog, warden, phantom, turtle, sniffer, goat
     (VL cuboid style, .b3d export, walk/idle/run animation frames)
8. [ ] Warden AI: hook into existing mcl_sculk vibration sensor events
9. [ ] Mineclonia spawn API support (mcl_mobs.register_spawner shape)

## Pitfalls (verified with luanti 5.16.1 + VoxeLibre 0.92.1, headless)

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
