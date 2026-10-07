"""Reusable mapped-skin bird pipeline. Run with Blender --background --python.

An asset-specific profile identifies anatomy; generic numbered bones are never
guessed automatically. Source files are read-only. All exports have one clip.
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

parser = argparse.ArgumentParser()
parser.add_argument('--input', required=True)
parser.add_argument('--profile', required=True)
parser.add_argument('--standard', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
out = Path(args.output).resolve()
out.mkdir(parents=True, exist_ok=True)
standard = json.loads(Path(args.standard).read_text(encoding='utf8'))
profile = json.loads(Path(args.profile).read_text(encoding='utf8'))
species = profile['species']
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH'
          and any(m.type == 'ARMATURE' for m in o.modifiers) and not o.hide_render]
if len(meshes) != 1:
    raise ValueError('This mapped-skin profile requires exactly one visible skinned mesh; curate other layouts first.')
mesh = meshes[0]
source_rig = next(m.object for m in mesh.modifiers if m.type == 'ARMATURE')
mapping = profile['sourceToStandard']
unknown = {g.name for g in mesh.vertex_groups} - set(mapping)
if unknown:
    raise ValueError(f'Unmapped source groups: {sorted(unknown)}')
positions = {b.name: (source_rig.matrix_world @ b.head_local,
                      source_rig.matrix_world @ b.tail_local) for b in source_rig.data.bones}
source_triangles = sum(len(p.vertices) - 2 for p in mesh.data.polygons)
# Normalize the author's coordinates while preserving mesh/rig alignment.
rotation = Matrix.Rotation(math.pi if profile['sourceForward'] == '-Y' else 0, 4, 'Z')
points = [rotation @ mesh.matrix_world @ v.co for v in mesh.data.vertices]
span = max(p.x for p in points) - min(p.x for p in points)
scale = profile['targetWingspanStuds'] / span
conversion = Matrix.Scale(scale, 4) @ rotation
world_matrix = mesh.matrix_world.copy()
weights = []
group_names = {g.index: g.name for g in mesh.vertex_groups}
for vertex in mesh.data.vertices:
    values = {}
    for group in vertex.groups:
        name = mapping[group_names[group.group]]
        values[name] = values.get(name, 0) + group.weight
    weights.append(values)
    vertex.co = conversion @ world_matrix @ vertex.co
mesh.parent = None
mesh.matrix_world = Matrix.Identity(4)
mesh.modifiers.clear()
mesh.vertex_groups.clear()
groups = {name: mesh.vertex_groups.new(name=name) for name in standard['hierarchy'] if name != 'Root'}
for index, values in enumerate(weights):
    top = sorted(values.items(), key=lambda p: p[1], reverse=True)[:4]
    total = sum(weight for _, weight in top)
    if total <= 0:
        raise ValueError(f'Unweighted source vertex {index}')
    for name, weight in top:
        groups[name].add([index], weight / total, 'REPLACE')
# Hide/remove importer visualization helpers; they are never exported.
for obj in list(bpy.context.scene.objects):
    if obj != mesh:
        bpy.data.objects.remove(obj, do_unlink=True)
mesh.name = profile['species'] + '_Geo'
mesh.data.name = mesh.name
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
decimate = mesh.modifiers.new('ProductionReduction', 'DECIMATE')
decimate.ratio = min(1, standard['budgets']['heroTriangles'] / source_triangles)
decimate.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=decimate.name)
# Limit/normalize again after simplification, preserving interpolated skin weights.
bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.00001)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.025)
bpy.ops.object.mode_set(mode='OBJECT')

rig = bpy.data.objects.new('BirdRig', bpy.data.armatures.new('BirdRig_v1'))
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
mesh.select_set(False)
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name, parent in standard['hierarchy'].items():
    bone = rig.data.edit_bones.new(name)
    if name == 'Root':
        bone.head = (0, 0, 0)
        bone.tail = (0, 0, 0.2)
        bone.use_deform = False
    else:
        start, end = profile['landmarks'][name]
        bone.head = conversion @ positions[start][0]
        bone.tail = conversion @ positions[end][0]
        if name.endswith('_Tip') or name == 'Tail':
            bone.tail = conversion @ positions[end][1]
        if name == 'Head':
            bone.tail = bone.head + Vector((0, 0, 0.3))
        if (bone.tail - bone.head).length < 0.01:
            raise ValueError(f'Degenerate bone {name}')
    bone.roll = 0
    if parent:
        bone.parent = rig.data.edit_bones[parent]
        bone.use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')
rig['RigVersion'] = standard['rigVersion']
rig['Species'] = profile['species']
rig.show_in_front = True
mesh.parent = rig
armature = mesh.modifiers.new('BirdSkin', 'ARMATURE')
armature.object = rig
mesh.data.materials.clear()
# One palette texture/material for mobile-friendly rendering. UVs are available
# for later painted textures; palette islands deliberately overlap by color.
palette = [(0.42,0.49,0.60,1), (0.25,0.30,0.40,1), (0.63,0.70,0.79,1), (0.95,0.59,0.20,1)]
image = bpy.data.images.new(profile['species'] + '_Palette', width=512, height=512)
pixels = []
for y in range(512):
    for x in range(512):
        pixels.extend(palette[x // 128])
image.pixels = pixels
image.filepath_raw = str(out / (profile['species'] + '_BaseColor.png'))
image.file_format = 'PNG'
image.save()
material = bpy.data.materials.new('BirdPalette')
material.use_nodes = True
shader = material.node_tree.nodes.get('Principled BSDF')
shader.inputs['Roughness'].default_value = 0.75
tex = material.node_tree.nodes.new('ShaderNodeTexImage')
tex.image = image
material.node_tree.links.new(tex.outputs['Color'], shader.inputs['Base Color'])
mesh.data.materials.append(material)
uv = mesh.data.uv_layers.active
for polygon in mesh.data.polygons:
    scores = {}
    center = sum((mesh.data.vertices[i].co for i in polygon.vertices), Vector()) / len(polygon.vertices)
    for index in polygon.vertices:
        for vg in mesh.data.vertices[index].groups:
            name = mesh.vertex_groups[vg.group].name
            scores[name] = scores.get(name, 0) + vg.weight
    dominant = max(scores, key=scores.get)
    band = 1 if ('Wing' in dominant or dominant == 'Tail') else 0
    if dominant in ('Neck','Head','Chest'):
        band = 2
    if 'Foot' in dominant or (dominant == 'Head' and center.y > 1.47 and center.z > 3.03):
        band = 3
    for loop in polygon.loop_indices:
        uv.data[loop].uv = ((band + 0.5) / 4, 0.5)

scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = standard['coordinates']['metersPerStud']
scene.render.fps = standard['fps']
rig.animation_data_create()
rest_rotations = {b.name: b.matrix_local.to_quaternion() for b in rig.data.bones}
def world_rotation(name, x=0, y=0, z=0):
    q = Quaternion((1,0,0),x) @ Quaternion((0,1,0),y) @ Quaternion((0,0,1),z)
    rest = rest_rotations[name]
    rig.pose.bones[name].rotation_quaternion = rest.inverted() @ q @ rest
def reset_pose():
    for bone in rig.pose.bones:
        bone.rotation_mode = 'QUATERNION'
        bone.rotation_quaternion = Quaternion()
        bone.location = Vector()
        bone.scale = Vector((1,1,1))
def pose_clip(name, t, duration):
    reset_pose()
    phase = 2 * math.pi * t / duration
    if name == 'Idle':
        flap = -0.32 + math.sin(phase)*0.025
        world_rotation('Head', z=math.sin(phase)*0.07)
        rig.pose.bones['Body'].location.y = math.sin(phase)*0.025
    elif name == 'Fly':
        flap = math.sin(phase)*0.68
        world_rotation('Body', x=-0.38)
        world_rotation('Tail', x=0.18)
        world_rotation('Leg_L', x=-0.6)
        world_rotation('Leg_R', x=-0.6)
    elif name == 'Glide':
        flap = 0.12 + math.sin(phase)*0.015
        world_rotation('Body', x=-0.4)
        world_rotation('Tail', x=0.18)
        world_rotation('Leg_L', x=-0.6)
        world_rotation('Leg_R', x=-0.6)
    elif name == 'TakeOff':
        u = t / duration
        flap = -0.32*(1-u) + math.sin(u*math.pi*3)*0.7*u
        world_rotation('Body', x=-0.38*u)
        world_rotation('Leg_L', x=-0.6*u)
        world_rotation('Leg_R', x=-0.6*u)
    else:  # Land
        u = t / duration
        flap = math.sin((1-u)*math.pi*2)*0.4*(1-u)-0.32*u
        world_rotation('Body', x=-0.4*(1-u))
        world_rotation('Leg_L', x=-0.6*(1-u))
        world_rotation('Leg_R', x=-0.6*(1-u))
    for side, sign in [('L',1),('R',-1)]:
        world_rotation(f'Wing_{side}_Upper', y=sign*flap)
        world_rotation(f'Wing_{side}_Mid', y=sign*flap*0.2)
        world_rotation(f'Wing_{side}_Tip', y=sign*flap*0.1)

actions = {}
clips = {}
# Coordinate conversion: Blender +Y forward, +Z up -> Roblox -Z, +Y up.
coordinate = Matrix(((1,0,0),(0,0,1),(0,-1,0)))
for name, definition in standard['proofClips'].items():
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    count = round(definition['duration'] * scene.render.fps)
    samples = []
    for frame in range(count + 1):
        t = frame / scene.render.fps
        scene.frame_set(frame + 1)
        pose_clip(name, t, definition['duration'])
        for bone in rig.pose.bones:
            bone.keyframe_insert('rotation_quaternion', frame=frame+1, group=bone.name)
            bone.keyframe_insert('location', frame=frame+1, group=bone.name)
        bpy.context.view_layer.update()
        rotations = {}
        for bone in rig.pose.bones:
            delta = bone.matrix.to_quaternion() @ rest_rotations[bone.name].inverted()
            mat = coordinate @ delta.to_matrix() @ coordinate.inverted()
            q = mat.to_quaternion()
            rotations[bone.name] = [round(v,7) for v in (q.w,q.x,q.y,q.z)]
        samples.append({'time': t, 'rotations': rotations})
    clips[name] = {'duration': definition['duration'], 'loop': definition['loop'], 'samples': samples}
    actions[name] = action
    action.pose_markers.new('Start').frame = 1
    if name in ('TakeOff','Land'):
        action.pose_markers.new('Complete').frame = count + 1

def select_export():
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = rig
def export_fbx(path, animated):
    select_export()
    bpy.ops.export_scene.fbx(filepath=str(path), use_selection=True,
        object_types={'MESH','ARMATURE'}, add_leaf_bones=False,
        use_armature_deform_only=False, bake_anim=animated,
        bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False,
        bake_anim_use_all_bones=True, bake_anim_force_startend_keying=True,
        bake_anim_step=1, bake_anim_simplify_factor=0,
        apply_unit_scale=True, apply_scale_options='FBX_SCALE_UNITS',
        axis_forward='-Z', axis_up='Y', path_mode='COPY', embed_textures=True)

rig.animation_data.action = None
reset_pose()
scene.frame_set(1)
export_fbx(out / f'{species}_Rig.fbx', False)
for name, action in actions.items():
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    scene.frame_start = 1
    scene.frame_end = round(standard['proofClips'][name]['duration']*scene.render.fps)+1
    scene.frame_set(1)
    export_fbx(out / f'{species}_{name}.fbx', True)
rig.animation_data.action = actions['Fly']
rig.animation_data.action_slot = actions['Fly'].slots[0]
scene.frame_start = 1
scene.frame_end = 25
scene.frame_set(1)
select_export()
bpy.ops.export_scene.gltf(filepath=str(out/f'{species}_Animated.glb'), export_format='GLB',
    use_selection=True, export_animations=True, export_animation_mode='ACTIONS')
bpy.ops.wm.save_as_mainfile(filepath=str(out / f'{species}_Production.blend'))
triangles = sum(len(p.vertices)-2 for p in mesh.data.polygons)
influence_errors = [v.index for v in mesh.data.vertices if not v.groups or len(v.groups)>4
    or abs(sum(g.weight for g in v.groups)-1)>0.001]
if triangles > 20000 or influence_errors or 'Root' in [g.name for g in mesh.vertex_groups]:
    raise ValueError('Rig/geometry validation failed')
report = {'rigVersion':standard['rigVersion'], 'species':profile['species'],
    'sourceTriangles':source_triangles, 'triangles':triangles,
    'vertices':len(mesh.data.vertices), 'bones':len(rig.data.bones),
    'maxInfluences':max(len(v.groups) for v in mesh.data.vertices),
    'unweightedVertices':len(influence_errors), 'rootWeights':False,
    'wingspanStuds':profile['targetWingspanStuds'], 'textureSize':512,
    'actions':list(actions), 'fps':scene.render.fps}
(out/'validation.json').write_text(json.dumps(report,indent=2), encoding='utf8')
(out/'proof-clips.json').write_text(json.dumps({'rigVersion':standard['rigVersion'],'clips':clips}),encoding='utf8')
print('BIRD_PIPELINE_COMPLETE',json.dumps(report))
