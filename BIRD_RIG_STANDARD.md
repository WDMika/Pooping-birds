# BirdRig_v1

The authoritative hierarchy, durations, axes and planning budgets are in `assets/characters/bird-standard-v1.json`. Sixteen bones:

```text
Root
└─ Body
   ├─ Chest
   ├─ Neck → Head
   ├─ Wing_L_Upper → Wing_L_Mid → Wing_L_Tip
   ├─ Wing_R_Upper → Wing_R_Mid → Wing_R_Tip
   ├─ Tail
   ├─ Leg_L → Foot_L
   └─ Leg_R → Foot_R
```

Root is at the contact origin, unweighted. Blender faces +Y, up +Z; Roblox faces -Z, up +Y. One Blender coordinate unit represents one stud using metric scale_length 0.28. Preserve the rest pose and bone names across species, but adapt lengths, weights and species offsets; retarget orientation against each imported bind pose. Four normalized influences maximum per vertex. No leaf/helper bones or imported debug meshes. One skinned mesh/material is the current pigeon convention; additional meshes require importer and visual-service review.

Meshy birds should have readable separate wing/leg/tail anatomy, accessible shoulder/neck joints, stylized proportions and no unnecessary feather microdetail. Connected skin is acceptable if it deforms cleanly; a fused silhouette without joint clearance needs artist retopology. The provided GLB already had 46 generic bones and useful weights. Its anatomical mapping is `assets/characters/meshy-character/profile.json`; new numbered rigs need a new inspected mapping, not this file copied blindly.

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/characters/build_bird.py -- --input 'C:/Users/mikai/Downloads/Meshy_AI_Character_output.glb' --profile assets/characters/meshy-character/profile.json --standard assets/characters/bird-standard-v1.json --output assets/characters/pigeon/v1
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/characters/verify_exports.py -- --directory assets/characters/pigeon/v1 --species Pigeon
```

For Raven, Seagull, Owl, Falcon or Eagle: inspect GLB → anatomical profile/landmarks → species-specific output directory → review deforming poses → import once → prove five clips. Unrigged Meshy assets require armature creation and manual/assisted weight painting first; the current builder accepts a single already-skinned mesh and rejects unknown groups. It is not an automatic rig generator for arbitrary anatomy.

Studio: File → Import `Pigeon_Rig.fbx`; keep **Bones without influence** so Root survives; inspect owner, scale and texture; move the Model to `ServerStorage.BirdCharacterTemplates.Pigeon`. Set RigVersion=BirdRig_v1 and Species=Pigeon. PrimaryPart=Pigeon_Geo; set its PivotOffset to Root.CFrame to correct imported armature-axis pivot rotation. Server-created AnimationController/Animator lives inside the model. `BirdVisualService` clones, welds and removes authoring folders; collision remains on the existing character root. Bone deformation changes appearance, not collision.

Current imported mesh ID: 98474860366246; texture ID: 91852723190945. Measured Studio mesh dimensions ≈6.4035 ×3.4092 ×3.3179 studs; 11,999 triangles, 16 bones, four influences, no unweighted vertices. Re-import and recheck ownership if restoring to another experience. Do not mark all other species as rigged because their gameplay records exist.
