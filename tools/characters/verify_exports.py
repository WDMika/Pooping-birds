"""Blender round-trip verification: one clip per FBX, rig, weights, scale and GLB actions."""
import bpy, json, sys, argparse, struct
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--directory',required=True);parser.add_argument('--species',default='Pigeon')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);directory=Path(args.directory).resolve()
standard=json.loads((Path(__file__).resolve().parents[2]/'assets/characters/bird-standard-v1.json').read_text())
reports=[]
for clip in ('Rig',*standard['proofClips']):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(directory/f'{args.species}_{clip}.fbx'))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    assert len(meshes)==len(rigs)==1,(clip,'unexpected objects')
    mesh,rig=meshes[0],rigs[0]
    hierarchy={b.name:b.parent.name if b.parent else None for b in rig.data.bones}
    assert hierarchy==standard['hierarchy'],(clip,hierarchy)
    assert all(1<=len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<.002 for v in mesh.data.vertices),clip
    assert len(mesh.data.uv_layers)>0 and len(mesh.data.materials)==1,clip
    triangles=sum(len(p.vertices)-2 for p in mesh.data.polygons);assert triangles<=20000
    assert len(bpy.data.actions)==(0 if clip=='Rig' else 1),(clip,len(bpy.data.actions))
    reports.append({'file':f'{args.species}_{clip}.fbx','triangles':triangles,'bones':len(rig.data.bones),'actions':len(bpy.data.actions),'importedDimensionsMeters':list(mesh.dimensions),'maxInfluences':max(len(v.groups) for v in mesh.data.vertices)})
raw=(directory/f'{args.species}_Animated.glb').read_bytes();size=struct.unpack_from('<I',raw,12)[0];data=json.loads(raw[20:20+size])
names={a['name'] for a in data.get('animations',[])};assert names==set(standard['proofClips']),names
report={'passed':True,'fbx':reports,'glbAnimations':sorted(names)}
(directory/'export-roundtrip.json').write_text(json.dumps(report,indent=2));print('EXPORT_ROUNDTRIP_OK',json.dumps(report))
