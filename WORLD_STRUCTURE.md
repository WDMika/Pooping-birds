# Vertical world production

Studio is the primary authoring environment. WorldConfig owns dimensions/layout; WorldBuilder creates a deterministic modular blockout; imported/manual art belongs in a separate `Workspace.BirdCity.Art` folder so a generated rebuild cannot destroy it. Archive and save before changing WorldVersion. Never globally scale the city to compensate for an imported asset's units.

Current hierarchy: Workspace.BirdCity → City (Infrastructure + six districts), Hub, Gameplay. Runtime Citizens, AnimalControl, Dogs, Food and Effects are server-owned. ServerStorage.WorldArchives stores previous generated geometry; it is not an off-machine backup. Templates belong in ServerStorage.ContentTemplates and BirdCharacterTemplates.

| Region | X / Z center | Purpose |
| --- | --- | --- |
| Floating Sanctuary | 0 /0, Y400 | Recovery, collection, shop/upgrades/daily kiosks, future nest systems |
| Starter City | Full 1640×1640 ground | Current beginner flight and survival region |
| Downtown | 0 /-260 | Towers, plaza, alley escapes and altitude routes |
| Residential | -550 /-260 | Low roofs, gardens, balconies and dogs |
| Commercial | 550 /-260 | Food/water loops, shop facades, awnings and signs |
| Park | -480 /400 | Pond, trees, bridge, benches and nature traversal |
| Industrial | 480 /390 | Warehouses, silos, containers, Bird Catcher depot |
| Outskirts | 0 /720 | Tree belt and future biome boundary; wilderness backend absent |

Project layer targets in studs: Ground Y0–6; trees/signs Y12–40; balconies Y12–70; low roofs Y28–60; high roofs Y80–180; towers Y180–315; sanctuary Y400; sky traversal above. These are build guides, not enforced physics limits. A route should offer three heights, a readable target lane, a food/water detour, a low-cover escape and a safe perch. At base speed 68 studs/s, a 200-stud link takes about three seconds; measure turning and stopping rather than only straight distance.

Rooftop checklist: collision supports landing; at least one clear 18×12-stud perch; readable edge; launch clearance; route to another usable surface; avoid canopy/antenna collision over the landing footprint. The two 7.5-stud alleys are precision challenges; ordinary corridors should allow two 6.4-stud-wing birds plus turning margin (initial target ≥20 studs). Add larger variants for future birds based on measured wingspan.

Markers are anchored invisible BaseParts under Gameplay, with CollectionService tags. Preserve FoodSpawn/WaterSpawn + FoodType (Config.Food key), NPCSpawn + District, DogSpawn, AnimalControlSpawn, ReturnToHub, HubInteraction + Page, FlightLaunch + District. Inspect WorldBuilder for exact attributes before adding markers. Place food/water and targets on a deliberate traversal loop, never in inaccessible decoration.

Streaming is currently enabled. Individual building/prop Models use Atomic where they must arrive together; don't make an entire district persistent. HubService requests sanctuary streaming before return. PopulationService caps citizens at24/dogs at6 and activates nearby districts. Test high-speed entry and unloaded landing targets; provide collision/readability before prompting interaction. Record instance count, frame time and streaming pauses in TESTING results. Future biomes get a new region config/kit and explicit server gates; do not enable PvP or progression by scenery alone.
