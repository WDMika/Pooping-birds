# POOPING BIRDS

POOPING BIRDS is a Roblox arcade flight game. Fly over Bird City, score hits on city citizens, earn Bird Points, manage health/hunger/thirst/stamina, and unlock birds while wanted officers pursue you.

## Production entry point

Read [PROJECT_STATE](PROJECT_STATE.md) for current evidence and limitations, [GAME_DESIGN](GAME_DESIGN.md) for the long-term loop, and [ASSET_PIPELINE](ASSET_PIPELINE.md) for reusable content workflows. [WORLD_STRUCTURE](WORLD_STRUCTURE.md), [BIRD_RIG_STANDARD](BIRD_RIG_STANDARD.md), [ANIMATION_STANDARD](ANIMATION_STANDARD.md), [CONTENT_LIBRARY](CONTENT_LIBRARY.md), [TESTING](TESTING.md), and [VERSION_CONTROL](VERSION_CONTROL.md) cover the remaining disciplines without duplicating code.

Run `node tools/production/check.mjs` for development metadata/source checks. Use `--release` for the stricter readiness audit; it intentionally fails while the recorded release gates remain pending. Asset records, audio cues and VFX recipes live under `assets`. Documentation describes planned content explicitly; it does not imply eggs, breeding or PvP are playable.

## Project layout

Meshy asset-generation MCP is configured and verified. See [the connection guide](tools/meshy/README.md) for credential storage, verification and the Blender/Studio import workflow.

The Rojo project is `game/default.project.json`. Its `src` tree maps to these Studio locations:

- `src/ServerScriptService/GameServer.server.luau` — `ServerScriptService.GameServer`, authoritative profiles, world, food, scoring, bird unlocks, survival, and wanted response.
- `src/ReplicatedStorage/Shared/Config.luau` — `ReplicatedStorage.Shared.Config`, bird/food/scoring/gameplay tuning.
- `src/ReplicatedStorage/Shared/UITheme.luau` — `ReplicatedStorage.Shared.UITheme`, interface design tokens.
- `src/StarterPlayer/StarterPlayerScripts/ClientController.client.luau` — `StarterPlayer.StarterPlayerScripts.ClientController`, flight and input.
- `src/StarterPlayer/StarterPlayerScripts/Controllers/UIController.luau` — `StarterPlayer.StarterPlayerScripts.Controllers.UIController`, responsive HUD and menus.
- `src/StarterPlayer/StarterPlayerScripts/Controllers/UIComponents.luau` — `StarterPlayer.StarterPlayerScripts.Controllers.UIComponents`, reusable interface widgets.

The HUD is built at runtime as `PlayerGui.PoopingBirdsUI`. `ServerScriptService.GameServer` creates `ReplicatedStorage.BirdRemotes.Action` and `Feedback`; the client requests actions, while the server owns points, unlocks, hit rewards, food collection, and wanted state.

## Controls

- Keyboard/mouse: WASD to fly, mouse to aim, Space to climb, Ctrl to dive, Shift to boost, Q or the on-screen drop button to drop, B to open the bird shop, and E near food to collect it.
- Controller: left stick to steer, A to climb, B to dive, left bumper to boost, and right trigger to drop.
- Touch: use Roblox's on-screen flight buttons and the HUD drop button; the E proximity prompt collects nearby food.

## Run and test

Rojo 7.7.1 is pinned in `rokit.toml`. Run these commands from this project directory:

```powershell
rojo serve game/default.project.json --port 34872
# In a separate terminal, when a build artifact is needed:
New-Item -ItemType Directory -Path game/build -Force | Out-Null
rojo build game/default.project.json --output game/build/POOPINGBIRDS.rbxlx
```

If this terminal has an older PATH, replace `rojo` with `& "$env:USERPROFILE\.rokit\bin\rojo.exe"`. Do not start a second server when port 34872 is already serving this project.

Open the existing POOPING BIRDS place in Studio, then Plugins → Rojo → Connect to `localhost:34872`. The project permits live sync only to place `119022971112182`. Review the initial sync changes. Edit scripts in `game/src`; Rojo sends those changes to Studio. Studio-only edits to managed scripts must be copied back to local source before reconnecting. Restart Play after script changes for a clean runtime; sync does not restart running services or invalidate cached ModuleScripts.

The manifest maps scripts only. Existing Workspace geometry, Lighting, ServerStorage archives and other unmapped objects are preserved. `WorldBuilder` supplies the generated world when it is absent. The Rojo build artifact therefore does not contain the full existing Studio map; continue editing the connected place and save it in Studio to preserve scene edits. Saving does not publish the experience.

Connection verified on 7 October 2026: Studio restarted with the installed plugin, connected to POOPINGBIRDS on port 34872, received and reverted a temporary comment through live sync, and all 13 script source hashes matched the local files afterward. BirdCity retained all 1,278 descendants across the initial sync, and production DataStore acquisition remained enabled.

In Studio, use Play to check onboarding, movement, food prompts, drops, the bird shop, insufficient-points feedback, respawns, and mobile/tablet layouts. Multi-client and live DataStore tests require a published test experience owned by the intended account. Studio DataStore read failures use a temporary, non-saving profile; live servers reject a join if data cannot be loaded so a temporary profile cannot overwrite saved progress.

Data is stored under `BirdCity_Player_v1` with `UpdateAsync`, bounded retries, a 60-second autosave, leave saves, and a bounded shutdown flush. Bird Points, owned/equipped birds, five upgrade tracks, and the UTC daily-reward streak are saved in the profile. Enable API Services only on a private test experience when testing persistence; do not test against production player data.

## Current scope and release checks

Implemented: the city flight loop, server-authored scoring and Bird Points, wanted response that scales police pursuit, low-altitude dog attacks, food-based survival, bird unlock/equip, responsive HUD, bird shop, five server-validated upgrade tracks, daily rewards, and profile persistence. The Phoenix bird is a labeled placeholder. Game passes, developer products, matchmaking, and admin commands are not configured.

Before a public release, verify DataStore round trips in the experience owner’s private test place, run two or more clients, test a physical phone and controller, inspect output/performance at target player counts, and configure age/content settings, thumbnails, and monetization only if those systems are added. No live place was published as part of this work.

## QA completed in Studio

- Play starts with no Luau output errors; the player remains at the roost with full health while idle.
- In a temporary Studio profile with DataStore reads and writes disabled, buying/equipping a Raven deducted 250 points and updated the character; each of the five upgrades deducted its cost and updated its server-authored level/effect.
- A Raven with Stamina level 1 drained about 5.9 stamina/second while boosting and recovered about 14.5/second, matching the configured bird and upgrade modifiers.
- The same non-saving profile claimed Day 1 for 50 points; a duplicate server request was rejected without awarding more points. Day 2–7 remained locked.
- A Q-triggered headshot scored 81 points at a 3.25× height-plus-upgrade multiplier and raised wanted to one star. An unaffordable upgrade request was rejected without changing currency or level.
- The food prompt appears within range; pressing E collects the food and updates hunger. The drop action is on Q/HUD/controller, so E remains available to the prompt.
- Phone/tablet layout sizing was simulated at narrow and mid-width viewports; verify on a physical device before release. The test profile was isolated from DataStore and discarded after the session.

The automated Studio screen capture did not render the 3D scene, although runtime raycasts hit the generated city geometry. Check the actual Studio graphics viewport before release. The Studio integration used for this pass exposes script editing and Play testing, but not place save or publish; save the open place in Studio after reviewing these changes. A private owned test place is still required for DataStore round trips and multiplayer release checks.

## October 7 gameplay foundation pass

Preserved the existing flight, shop, daily rewards, scoring contracts and UI theme.

- ServerScriptService.Services.ImpactService: seven-second welded NPC/world/player splats, bounded at 80 active effects; effects do not collide or interfere with raycasts. Player hits do not enable city PvP.
- Shared.Config.Audio: replace the empty Release, Projectile, Impact, TargetHit and Headshot SoundId values with permitted Roblox audio IDs. These are deliberate silent placeholders, not final audio.
- Shared.Config.BirdOrder / Birds: Seagull added, BodyPower and extensible stats centralized; future zone/breeding fields do not enable unbuilt content.
- Services.ThreatService: fictional Bird Catchers with telegraphed, dodgeable nets, line-of-sight checks, short trap, defeat and respawn. Dogs use bounded height/range checks and server-owned leaps.
- Services.ProgressionSchema: schema 3 extends BirdCity_Player_v1 with reserved future records and preserves unknown fields. No full breeding, incubation or PvP implementation.
- Resource spawns: tag an anchored BasePart FoodSpawn or WaterSpawn and set its FoodType attribute to a Config.Food key. The server uses its Position; absent configured spawns, the existing city gets 18 default markers.
- Existing UI: seven bird cards, Body Power, updated rarity colors, capture/death transition. Flight brakes while input is blocked. Equipping birds/upgrading health no longer refills current health.

Verified in isolated Studio sessions without profile reads/writes: live projectile headshot awarded 50 points and one wanted star; NPC head splat welded correctly; moving NPC kept the splat attached with zero measured error; effect expired after seven seconds. Net capture produced a full-health respawn, unchanged point balance and cleared capture state. Dog leap reached Y4.28 from Y2; close-range damage worked; a bird 40 studs above received no damage (normal regeneration continued). Schema 3 preserved a sample unknown field and existing egg record. Output was clean. Production DataStore acquisition restored after QA.

Release gates still pending: real multiplayer and device input coverage, hosted persistence roundtrip/session concurrency audit, final audio IDs, complete visual world review, and saving/publishing the Studio place. Local sources are saved; no publication is claimed.

## World rework — 7 October 2026

The current world is now a 1,640 × 1,640 six-district city (9.95× the old playable area), with a large floating sanctuary at Y400, useful rooftops, narrow alley routes, capped district populations and Return to Nest (H / controller Y / HUD / world perches). Existing flight, currency, scoring and UI were preserved. The generated world is present in Studio Edit mode.

See game/WORLD_REWORK.md for hierarchy, scale, integration points and runtime evidence. Main modules: Shared.WorldConfig, Services.WorldBuilder, PopulationService and HubService. Production saving is enabled; no place publication is claimed.
