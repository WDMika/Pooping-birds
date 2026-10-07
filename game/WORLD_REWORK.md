# POOPING BIRDS — world pass, 7 October 2026

Implemented in Pooping Birds, place 119022971112182, and saved in the local source project. Studio remains in Edit mode with the generated map present. Publishing/place save is not claimed.

## Scale and layout

The old source generated a 520 × 520 city: 270,400 square studs. The new land is 1,640 × 1,640: 2,689,600 square studs, 9.95 times the playable ground area. Objects were rebuilt as modular structures rather than globally scaled.

The inspected pigeon visual is approximately 3.02 × 2.33 × 5.28 studs; its root is 2 × 2 × 1. Base flight remains 68 studs/second and camera zoom remains 10–32. No bird/NPC/UI scale multiplier was applied. Major boulevards are 56 studs wide, local streets 32–44, sidewalks 12. Houses, shops, warehouses and towers provide a 28–315-stud skyline, including rooftop equipment. Two deliberate 7.5-stud alleys reward low-flight precision.

| District | Center X/Z | Role |
| --- | --- | --- |
| Downtown | 0 / -260 | Towers, clock plaza, alley runs, dense target routes |
| Residential | -550 / -260 | Houses, gardens, roof decks, dogs |
| Commercial | 550 / -260 | Restaurants, shops, awnings, food and target routes |
| Park | -480 / 400 | Pond, bridge, trees, lookout, benches and dogs |
| Industrial | 480 / 390 | Warehouses, containers, silos, Animal Control depot |
| Outskirts | 0 / 720 | Tree belt, future wilderness trail; no expansion backend |

Aviator Plaza connects the park and freight side with a fountain and progressively taller flight perches. Rooftops have landing perches, food, HVAC, water towers, chimneys, antennae and clear observation positions.

## Sanctuary

A 540 × 420 floating island at Y400, tapered earth/rock underside, clouds, gardens, kiosks and paths. Four launch edges offer city routes. The spawn pad is at (0,405,148); safe return places the root near (0,410,148).

Physical zones: SpawnPlaza, BirdShop, UpgradeArea, NestArea, IncubatorArea, BreedingArea, RewardArea, Leaderboards, SocialArea, LaunchAreas and PvPArena. Current shop, bird collection, upgrades and daily kiosks open the existing UI through server-validated prompts. Nest/future zones have IntegrationId attributes. Incubation/breeding/ranked systems remain reserved.

The arena has a separate bridge, 190-stud floor, 110-stud flight volume, elevated spectator perches and guide geometry. PvPEnabled is false; no city or sanctuary PvP was enabled.

## Architecture

Workspace.BirdCity retains existing gameplay folder contracts (Citizens, Dogs, AnimalControl, Food, Effects). New geometry is organized under City districts and Hub. Gameplay contains NPCSpawns, AnimalControlSpawns, DogSpawns, FoodSpawns, WaterSpawns and ReturnPerches. Generated prior city geometry is archived in ServerStorage.WorldArchives; source backup is game/backups/GameServer.pre-world-v2.luau.

Shared.WorldConfig centralizes dimensions, districts, return rules and population budgets. Services.WorldBuilder builds idempotently. Services.PopulationService activates near birds, despawns far districts with hysteresis and caps active citizens at 24 and dogs at 6. Initial sanctuary population is zero; nearby city target clusters activate during descent. Catchers use district spawn markers instead of the old fixed station coordinates. Flee behavior stays local rather than returning NPCs to the prototype bounds.

Services.HubService implements H / controller Y / HUD Return to Nest, plus six world return perches. It validates alive/profile/capture/PvP state, blocks wanted and recent dog damage, channels for two seconds, cancels movement, loads the streamed destination, enforces a 20-second cooldown and resets flight/movement sampling after teleport. No currency or profile reset occurs.

StreamingEnabled was already true and remains enabled. Buildings and reusable props use Atomic models. Static generated map: 998 BaseParts, 38 buildings, 72 resource markers, 33 NPC route markers, six catcher markers, six dog markers and four launch points. Resource instances are created during play. These are budget counts, not a claim of measured device FPS.

## Verification

- Studio startup and final test Output were clean. Tests used isolated profiles with no DataStore reads or writes; production store acquisition was restored afterward.
- Spawn: one sanctuary SpawnLocation, root around Y410; main menu, HUD, camera and flight remained functional.
- Keyboard climb and launch/descent passed; a real flight reached roughly (0,260,534) from the sanctuary.
- Park activation: five citizens / two dogs. Switching to Commercial produced eight citizens and removed distant park actors. Global caps are enforced in source; real multi-client stress testing remains pending.
- Commercial headshot: +75 Bird Points, Wanted 1, attached splat and a district catcher. H return was denied during pursuit.
- Return from park: root stayed near (0,410,148); a repeat request produced the cooldown message. Recent dog damage also prevented immediate return.
- Dogs: low bird health decreased about seven net points during the test; a high bird received no damage and continued natural health regeneration.
- Plaza water collection: thirst rose from 30 to approximately 62; the collected resource hid for its existing respawn delay.
- Death: respawn at the sanctuary, health 100, wanted reset, 50 test points retained.
- Hub Bird Shop E prompt opened the existing BIRD SHOP panel.
- Roof scan: all 38 rooftop food positions have clear landing-perch surfaces; sloped roofs and tower crowns were corrected.
- Builder repeat call produced no duplicate instances. Edit screenshots verified the expanded layout, sanctuary silhouette and launch view over the city.

Remaining release checks: real multiplayer, physical mobile/controller inputs, performance profiling on low-end devices, hosted persistence and place saving/publishing. This pass does not implement future breeding, incubation, ranked PvP or wilderness content.
- Capture integration was reconfirmed in the expanded park using a temporary QA catcher: trapped state observed, clean sanctuary respawn, health 100, Wanted 0 and Captured false.
- Removed the obsolete prototype-coordinate resource fallback; resource placement now comes exclusively from the expanded world's tagged markers.
