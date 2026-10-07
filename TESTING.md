# Production checks

Run from project root: `node tools/production/check.mjs`. It validates required docs, registry records and referenced files, category/cue coverage, character export evidence, Rojo paths/place restriction, and production DataStore acquisition. It does not prove runtime behavior. `--release` additionally rejects incomplete release gates and required content that is not approved; development can be coherent while a release is blocked.

Build scripts with Rojo7.7.1: `rojo build game/default.project.json --output game/build/POOPINGBIRDS.rbxlx`. Verify FBX with Blender `--background --python tools/characters/verify_exports.py -- --directory assets/characters/pigeon/v1`. Reports must identify actual results, date, environment, commit and limitations. Do not copy previous QA claims into a new pass without re-running relevant cases.

Before Play tests, use an owned private test place/profile namespace with production reads/writes disabled. Do not depend on a failed API request as isolation. If temporarily changing source for QA, capture it first and restore production acquisition after Stop, even on test failure. Record the disabled store/namespace in evidence. Current production namespace is BirdCity_Player_v1, schema3; reserved future fields must survive migration. Saving a scripts-only build does not snapshot live data or the full Studio scene.

| Gate | Required evidence |
| --- | --- |
| Core loop | Join→fly→drop→NPC hit→points→wanted→escape; distance/rate/spam rejection, no duplicate reward |
| Survival | Food/water proximity validity, stamina boost/regeneration, damage, capture/respawn, unchanged currency |
| Progression | Buy/equip/upgrade/daily states, insufficient points, duplicate request, rejoin round trip, concurrent-session audit |
| Characters | Import scale/axes/bones/weights; all five clips, actual published IDs; equip/respawn/leave cleanup; other species fallback |
| World | Ground/tree/sign/balcony/roof/tower routes; high-speed streaming entry; usable roofs; safe hub return/load |
| UI/input | Small phone/tablet/desktop, physical touch/controller, modal focus and restored flight input, no HUD overlap |
| Audio | Rights and owner permissions, moderation, loop seams, mix, muted settings, voice cleanup, target-experience playback |
| VFX | Hit attachments remain aligned, TTL/caps, no collision/query impact, reduced-effects path, crowded hits |
| Multiplayer | ≥2 clients: late join, replication, owner animation, hit rewards, capture, disconnect/despawn; NPC authority |
| Performance | Client median/p95 frame time and memory, server frame time, network rate, peak instances/voices/particles; baseline vs candidate |
| Recovery | Restore Git snapshot + asset sources + full saved scene on a separate copy; reconnect Rojo; rebuild/import smoke test |

Initial project performance target: stable30fps on the chosen low-end phone and60fps on the chosen desktop at the selected player count. Device models/player count and measurements must be recorded before this target is accepted. If a metric regresses, reduce measured geometry/texture/instance/particle/audio cost rather than adding undocumented global settings.

Open release gates live in `assets/release-gates.json`. Mark a gate passed only with an evidence file/URL and review date. The production checker deliberately returns nonzero until all gates pass. Runtime Studio audit script: `tools/production/studio-audit.luau`; run in Edit with Studio MCP/Command Bar for structure and tag evidence, never for gameplay/data claims.
