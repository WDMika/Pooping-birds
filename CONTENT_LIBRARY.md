# UI, audio and VFX production

## UI coverage and handoffs

Keep one runtime ScreenGui, `PlayerGui.PoopingBirdsUI`, built by UIController with UIComponents and Shared.UITheme. Preserve the central flight view. HUD priorities are Bird Points, health, hunger, thirst, stamina, wanted stars, poop cooldown and last-hit multiplier; secondary management lives in a modal. Use real replicated state, safe-area spacing, readable text, touch targets at least44px, explicit controller focus, and short replaceable tweens.

| Required surface | Current status | Production contract |
| --- | --- | --- |
| HUD | Implemented | Existing resource/points/wanted/cooldown/multiplier updates |
| Bird Collection | Implemented BIRDS page | Owned/equipped/locked states, real Config stats; validated EquipBird |
| Shop | Implemented SHOP page | Bird Point unlocks, insufficient funds; no fake Robux products |
| Upgrades | Implemented UPGRADES | Five tracks and server-validated prices/levels |
| Daily Rewards | Implemented DAILY | Claimable/claimed/locked, duplicate claim rejected |
| Nest | Sanctuary scenery/return only | Future owned nest overview; server ownership before edit actions |
| Eggs | Reserved schema only | Future owned egg inventory, rarity and truthful outcomes |
| Incubator | Scenery only | Future slots/timer/status; server UTC completion and idempotent hatch |
| Breeding | Scenery/reserved data | Future valid parents, cost, cooldown and server result |
| Challenges | Not implemented | Future server progress and idempotent claim ledger |
| PvP | Disabled arena scenery | Future opt-in queue, eligibility, result and rating server-owned |
| Settings | Controls disclosure only | Future audio/motion/accessibility/input preferences; no false toggles |

For each new page specify loading/empty/owned/locked/busy/error/success states, narrow-screen layout and controller navigation before implementation. Figma for larger compositions should reuse current theme tokens and component vocabulary, document real server data contracts, and export only necessary raster art. Store file/node URLs and exported sources in `assets/ui/<screen>/vN`. Do not add working-looking purchase/hatch controls to absent backends. Review 360×800, 768×1024, 1920×1080, touch and controller; physical devices remain a release gate.

## Audio

`assets/audio/library.json` defines every requested cue, canonical name, bus, looping and integration hook. Masters live in `assets/audio/<category>/<cue>/vN/source`; exports in `exports`. Record owner, rights proof/source, editor, sample rate, channels, duration, loop seam, normalization and Roblox ID/experience permissions. Record dry sounds, trim silence, remove clicks, check mono positional cues and smooth ambient loop seams. Project master target: PCM WAV,48kHz,16-bit; short peaks ≤-3dBFS, consistent perceived levels. These are project targets; verify current Roblox upload limits separately.

SoundService bus convention: PB_Master, PB_SFX, PB_Ambience, PB_UI. Positional bird/impact/environment sounds belong under an Attachment/BasePart; UI feedback uses the UI bus without spatial rolloff. Mix from low initial volume; cap one-shot voices at48/client, sustained flight loops at2/bird, ambience at4/client. Fade/stop loops on state change, character replacement and stream-out. Loops require explicit ownership and stop handles; Debris-only playback is suitable for short effects, not permanent wind.

Current actual playback route is ImpactService.PlaySound using Shared.Config.Audio: Release→Poop_Release; Projectile→Poop_Projectile; Impact→Poop_Splat; TargetHit→Poop_Reward; Headshot→Poop_Headshot. All five IDs are empty and intentionally silent. The expanded library does not claim recorded/uploaded sounds. Bird markers may cue flaps; flight state chooses wind; server accepted Feedback cues rewards/wanted/capture; future hatch/PvP cues await real backends. Check moderation, ownership, permission and audible playback in the target private experience before approval.

## VFX

`assets/vfx/library.json` records bounded reusable effect recipes, ownership and implementation status. Poop splats currently run through ImpactService.Splat: ≤80 active,7s TTL, non-colliding/non-queryable, welded to moving targets. Hit/headshot and score feedback use UIController.animateHit; their typography inherits UITheme.

Extend these routes rather than replacing hit/reward rules. Server chooses hit position/type and reward; observers create optional particles locally within a distance budget. Use existing Feedback where the payload already fits; don't introduce a remote per particle. Client-generated effects never select damage or points. Cap effect lifetime, emit count, visible distance and concurrent instances; support reduced effects and clean connections/tweens on respawn/stream-out. Reserve hatch, legendary, PvP, ability, trail and cosmetic hooks until their systems exist. Trails require Attachment endpoints, lifetime and enable/disable cleanup; cosmetics need owned/equipped server validation before replication.

Review feedback at low/high altitude, overlapping multiplayer hits and mobile frame times. Effects must retain target/escape readability; a rare reward can be vivid but must not cover flight controls. No catalog status is an FPS claim: capture measurements at the planned player count.
