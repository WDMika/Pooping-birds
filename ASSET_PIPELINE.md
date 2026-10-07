# Content production pipeline

## Source of truth

`game/src` owns Rojo-managed Luau; `game/default.project.json` targets only place **119022971112182**. Studio owns scene authoring and imported asset bindings. `assets/catalog.json` records source, rights, category, version, integration and approval status. Never overwrite source exports: create `v2`, then promote after review. Generated validation reports accompany exports; a registry entry alone is not proof that an asset works.

Folder convention: `assets/<category>/<asset-slug>/v<integer>/{source,exports,proof}` for new content. Existing pigeon files remain at `assets/characters/pigeon/v1` for compatibility. Categories: characters, environment, props, npcs, ui, audio, vfx. Name instances `PB_<Category>_<Asset>_v01`; audio cues use `PB_<Category>_<Cue>_v01`. Keep display names independent from stable integration IDs.

Each asset needs: purpose in the loop, creator/source URL or Meshy task ID, rights status, version, source files, export files, dimensions/origin, triangle/texture budgets, collision approach, Roblox owner/asset IDs, integration path, dependencies and QA evidence. Planned and blockout content is allowed, but only `approved` content can pass the release gate.

## Toolchain

| Tool | Responsibility | Handoff |
| --- | --- | --- |
| ChatGPT / design docs | Game decisions and acceptance criteria | Concrete feature/asset brief |
| Codex | Modular Luau, automation, validation, documentation | Local reviewed source + evidence |
| Meshy | Optional base asset generation | GLB plus generation metadata and rights review |
| Blender 5.2 | Cleanup, modeling, UVs, rigging, animation | Editable blend, FBX/GLB, baked PNG, reports |
| Figma | Larger multi-screen UI composition when useful | File/node links, tokens, states and Roblox object mapping |
| Rojo 7.7.1 | Local scripts ↔ connected Studio | Port 34872; restart Play after source changes |
| Roblox Studio | Level design, imports, asset ownership, device/server tests | Saved scene + QA evidence; publish separately |
| Git / GitHub | Reviewable history and backups | Branch, commit, owner-approved remote visibility, recoverable asset sources |
| Audio editor | Record/edit/trim/normalize/loop | WAV master and upload-ready export with rights record |

Use existing UITheme/UIComponents instead of introducing a second theme. Figma is optional for this workflow: no Figma file is claimed until created and linked. No audio editor is currently configured; Audacity or another owned editor can produce the masters. Meshy credentials remain in encrypted user storage, outside assets, Luau, Git and documentation.

## Environment / prop workflow

Brief a modular kit rather than a whole city: building facade/roof/balcony, tree/trunk/canopy, rocks, food/trash, bench, street props/signs, Animal Control equipment, nests/incubators/shop kiosk, and future PvP arena props. Generate only when primitives or existing kit pieces cannot meet the silhouette. Meshy prompt: stylized Roblox scale, clean separate functional elements, broad colors, low/medium geometry, no text, no microdetail, usable landing surfaces and modular seams.

In Blender: inspect connected pieces; remove hidden/internal duplicates and degenerate faces; correct normals; apply mesh transforms; place origin at ground/contact/socket; unwrap or preserve texture UVs; bake unsupported procedural materials into PNG; use one material where practical; make a simple collision proxy. Project planning budgets: small prop ≤1,500 triangles, hero prop ≤5,000, modular building segment ≤8,000, tree ≤2,000, 512px textures (1024 only with measured need). These are project budgets, not universal platform limits. Record exceptions and measure them on target devices.

Export a single reusable piece, not a district-sized mesh. Import into a staging area in Studio; verify studs, orientation, material, collision and streaming. Store reusable approved templates under `ServerStorage.ContentTemplates.<Category>`, place anchored copies in the intended district, and record IDs/paths in the catalog. Visual meshes should not act as complex collision; keep flight corridors and rooftop contact surfaces simple. Reuse mesh and texture IDs across copies.

## NPC workflow

Citizens, dogs and Bird Catchers currently use primitive rigs from GameServer/PopulationService/ThreatService. Replace presentation through an adapter while preserving Humanoid/root, NPCType, damage/range contracts and server network ownership. Dogs need their own quadruped rig family; never rename bird bones onto unrelated anatomy. Keep spawn markers and population caps; prove walking/attack/death, hit splats, capture, despawn and late join with two clients before promoting an NPC skin.

## Characters

See `BIRD_RIG_STANDARD.md` and `ANIMATION_STANDARD.md`. The supplied Meshy bird is mapped by an explicit anatomical profile, not generic-name guessing. Preserve raw input. Current automated cleanup/decimation proves the pipeline but does not replace an artist's topology, fold, feather-intersection and weight-paint review. Palette UV islands intentionally overlap; they are not a unique paint-ready unwrap.

## Audio and VFX

Full cue/effect inventories and implementation routes are in `CONTENT_LIBRARY.md`; machine-readable definitions are in `assets/audio/library.json` and `assets/vfx/library.json`. Unassigned audio IDs remain silent. Do not invent usable sounds, hatch results, cosmetics or PvP rewards. Visual effects never award points or decide hits.

## Promotion and rollback

Run `node tools/production/check.mjs`; run the relevant Blender round-trip check; record Studio checks from `TESTING.md`; review all nine design questions; update catalog status and PROJECT_STATE. Commit source, exported assets, catalog and evidence together. Save a full Studio scene before a major scene edit; a scripts-only Rojo build is not a full scene backup. See `VERSION_CONTROL.md` for recoverable local snapshots, owner-approved GitHub sync and rollback.

Reference constraints: [Roblox modeling specifications](https://create.roblox.com/docs/art/modeling/specifications), [audio assets and permissions](https://create.roblox.com/docs/audio/assets), [performance guidance](https://create.roblox.com/docs/performance-optimization/improve), [instance streaming](https://create.roblox.com/docs/workspace/streaming). Recheck current limits before new production imports.
