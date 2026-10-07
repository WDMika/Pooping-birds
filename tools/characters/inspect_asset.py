"""Inspect and render a supplied GLB without modifying the source."""
import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--input', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
output = Path(args.output).resolve()
output.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=args.input)
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
rigs = [obj for obj in bpy.context.scene.objects if obj.type == 'ARMATURE']
report = {
    'blender': bpy.app.version_string,
    'source': args.input,
    'meshes': [{'name': obj.name, 'vertices': len(obj.data.vertices),
                'triangles': sum(len(p.vertices) - 2 for p in obj.data.polygons),
                'dimensions': list(obj.dimensions), 'uv_layers': len(obj.data.uv_layers),
                'groups': [g.name for g in obj.vertex_groups],
                'materials': [slot.material.name if slot.material else None for slot in obj.material_slots],
                'color_attributes': [a.name for a in obj.data.color_attributes]}
               for obj in meshes],
    'rigs': [{'name': rig.name, 'bones': [{'name': b.name,
               'parent': b.parent.name if b.parent else None,
               'head': list(b.head_local), 'tail': list(b.tail_local)}
               for b in rig.data.bones]} for rig in rigs],
    'actions': [a.name for a in bpy.data.actions],
    'images': [{'name': i.name, 'size': list(i.size)} for i in bpy.data.images],
}
(output / 'source-inspection.json').write_text(json.dumps(report, indent=2), encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'source-import.blend'))
points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
lower = Vector([min(p[i] for p in points) for i in range(3)])
upper = Vector([max(p[i] for p in points) for i in range(3)])
center = (lower + upper) / 2
extent = max(upper - lower)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.render.resolution_x = 1000
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.world = bpy.data.worlds.new('InspectionWorld')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (0.12, 0.15, 0.2, 1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = 0.6
for label, pos, power, size in [('Key',(3,-4,5),550,4), ('Fill',(-4,-2,3),350,4), ('Rim',(1,4,5),650,3)]:
    light = bpy.data.lights.new(label, 'AREA')
    light.energy = power * extent ** 2
    light.shape = 'DISK'
    light.size = size * extent
    obj = bpy.data.objects.new(label, light)
    scene.collection.objects.link(obj)
    obj.location = center + Vector(pos) * extent
    obj.rotation_euler = (center - obj.location).to_track_quat('-Z', 'Y').to_euler()
camera = bpy.data.objects.new('InspectionCamera', bpy.data.cameras.new('InspectionCamera'))
scene.collection.objects.link(camera)
camera.data.type = 'ORTHO'
camera.data.ortho_scale = extent * 1.5
scene.camera = camera
for view, direction in [('front', (0,-5,1)), ('side', (5,0,1)), ('three-quarter', (4,-5,2))]:
    camera.location = center + Vector(direction) * extent
    camera.rotation_euler = (center - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(output / f'source-{view}.png')
    bpy.ops.render.render(write_still=True)
print('INSPECTION_COMPLETE', json.dumps({'meshes': len(meshes), 'bones': sum(len(r.data.bones) for r in rigs)}))
