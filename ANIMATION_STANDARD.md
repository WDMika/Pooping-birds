# Shared animation standard

BirdRig_v1 uses 30 fps, in-place motion and one clip per FBX. Export mesh+armature, no leaf bones, no NLA/all-action bake, no animation simplification, axis -Z forward/+Y up and embedded palette texture. `Pigeon_Rig.fbx` has no animation; separate Idle/TakeOff/Fly/Glide/Land FBXs each have one. The archival animated GLB contains all five. `export-roundtrip.json` verifies this distinction.

Proof clips: Idle 2s loop; TakeOff 0.8s one-shot; Fly 0.8s loop; Glide 1.6s loop; Land 0.7s one-shot. Reserve Walk, Hop (Run alias), FastFly, Dive, Brake, TurnLeft/Right, Eat, Drink, Poop, Attack, Hit, Stunned, Sleep and Death (Knockout alias). Reserved names are not authored clips; current state fallbacks are declared in BirdAnimationConfig.

Exact modules:

| Studio path | Responsibility |
| --- | --- |
| ReplicatedStorage.Shared.BirdAnimationConfig | Shared IDs, species overrides, fallbacks, loops, offsets |
| ReplicatedStorage.Shared.BirdAnimationState | Ground hysteresis, locomotion and timed accepted actions |
| ReplicatedStorage.Shared.BirdProofClips | Generated rotation samples; do not edit manually |
| ReplicatedStorage.Shared.BirdAnimationSequenceBuilder | Editable Studio preview sequences from imported bind poses |
| ServerScriptService.Services.BirdVisualService | Validated template mount; server-created Animator; action serial |
| StarterPlayer.StarterPlayerScripts.Controllers.BirdAnimationController | Cache tracks, blend, select clips, clean up replacement/respawn |
| StarterPlayer.StarterPlayerScripts.ClientController | Feed movement intent, velocity, grounded ray and capture state |

Standing→Idle; leaving ground→TakeOff; active flight→Fly; boost→FastFly (Fly at 1.35× until authored); no flap→Glide; fast descent→Dive (Glide fallback); ground contact→Land; server-accepted drop→Poop; health decrease→Hit. Missing action clips retain locomotion presentation; they do not simulate a completed Poop/Hit animation. Current Death/Stunned fallbacks need dedicated art before final animation release.

Publish each FBX clip through Studio's Animation Editor under the experience owner, then assign real `rbxassetid://...` values in SharedIds or Species[species].Ids. Verify load, loop, duration, markers and multiplayer replication on an owned private test place. Start/Complete markers in generated preview sequences are authoring metadata; arbitrary Blender markers are not assumed to become Roblox event markers. Add gameplay markers in Animation Editor where needed; damage/rewards/cooldowns stay server timed.

StudioPreview=true registers temporary clips through AnimationClipProvider for local Animator tests. Temporary IDs must never be stored as production IDs. Outside Studio, missing IDs use the explicit ProofPose rotation bridge; this omits Blender positional bob and is not evidence of published animation replication. Owning player starts tracks on a server-created Animator inside their character; NPC Animator tracks must be started by the server. Species-specific clips can override shared names without changing the movement controller.

Regenerate Luau after Blender sample changes with Blender `--background --python tools/characters/generate_runtime.py`. This generator currently uses the pigeon proof library; extend its input before promoting a species-specific sample set. Verify neutral rest, shoulder/elbow/tip weights, left/right symmetry, planted feet, no intersections, takeoff/landing transition, respawn/equip cleanup and stream-out recovery.
