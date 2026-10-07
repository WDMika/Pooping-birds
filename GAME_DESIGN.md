# POOPING BIRDS — design contract

Fly → Poop → Hit → Earn → Survive → Escape → Progress. Every content change must strengthen this loop before adding a new system.

Players are stylized birds flying through a readable, vertical city. Target routes, altitude bonuses, food, water and escape perches create decisions during flight. The floating sanctuary is a safe place to recover and manage progression. City player hits do not enable PvP; a future voluntary arena must have explicit entry/exit rules.

Art direction: original colorful Roblox stylization, clean silhouettes, broad material/color regions, readable landmarks, playful fictional Bird Catchers. Preserve the sky/cream/ink/yellow interface palette in `UITheme`; avoid microscopic details and screen-filling effects.

Current progression: Bird Points, bird unlock/equip, five upgrades, daily rewards and survival resources. Nest ownership, eggs, incubation, breeding, challenges, ranked PvP and future biomes are planned; reserved schema fields and scenery do not make them playable.

For every proposal, record its effect on flight, the loop, long-term progression, art style, Roblox performance, reuse, extensibility, multiplayer and server authority. Reject decorative complexity that blocks target visibility or worsens flight. A cosmetic must never change collision, damage or authoritative movement.

Deliver one complete slice at a time: design contract → reusable content → server rules → client presentation → failure states → Studio/device/multiplayer evidence → release review. New progression grants require idempotency and persistence tests before UI purchase/claim actions are enabled.

Start in `PROJECT_STATE.md`; production instructions are in `ASSET_PIPELINE.md`, spatial rules in `WORLD_STRUCTURE.md`, and executable checks in `TESTING.md`.
