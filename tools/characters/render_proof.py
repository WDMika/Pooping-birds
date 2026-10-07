import argparse
import json
import sys
from pathlib import Path
import bpy
from mathutils import Vector

p = argparse.ArgumentParser()
p.add_argument('--blend', required=True)
p.add_argument('--output', required=True)
a = p.parse_args(sys.argv[sys.argv.index('--')+1:])
out = Path(a.output).resolve()
out.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(Path(a.blend).resolve()))
scene = bpy.context.scene
rig = bpy.data.objects['BirdRig']
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.render.resolution_x = 700
scene.render.resolution_y = 600
scene.render.resolution_percentage = 100
scene.world = bpy.data.worlds.new('ProofWorld')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (0.08,0.12,0.18,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = 0.6
target = Vector((0,0,1.6))
for name, loc, energy in [('Key', (5,7,8),1400),('Fill',(-6,3,4),900),('Rim',(0,-5,6),1600)]:
    data = bpy.data.lights.new(name,'AREA')
    data.energy = energy
    data.size = 6
    obj = bpy.data.objects.new(name,data)
    scene.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = (target-obj.location).to_track_quat('-Z','Y').to_euler()
camera = bpy.data.objects.new('ProofCamera',bpy.data.cameras.new('ProofCamera'))
scene.collection.objects.link(camera)
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 8.2
camera.location = (5,8,4)
camera.rotation_euler = (target-camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera = camera
for name, frame in [('Idle',1),('TakeOff',14),('Fly',7),('Glide',1),('Land',12)]:
    action = bpy.data.actions[name]
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    scene.frame_set(frame)
    scene.render.filepath = str(out/(name+'.png'))
    bpy.ops.render.render(write_still=True)
print('PROOF_RENDERS_COMPLETE')
