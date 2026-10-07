import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const release=process.argv.includes('--release'), errors=[];
const assert=(ok,message)=>{if(!ok)errors.push(message);};
const exists=p=>fs.existsSync(path.join(root,p));
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
const docs=['GAME_DESIGN.md','PROJECT_STATE.md','ASSET_PIPELINE.md','ANIMATION_STANDARD.md','BIRD_RIG_STANDARD.md','WORLD_STRUCTURE.md','CONTENT_LIBRARY.md','TESTING.md','VERSION_CONTROL.md'];
for(const doc of docs)assert(exists(doc),`Missing ${doc}`);
try{
 const project=read('game/default.project.json');assert(project.servePlaceIds.length===1&&project.servePlaceIds[0]===119022971112182,'Unexpected Rojo place restriction');
 const walk=n=>{for(const [key,v]of Object.entries(n)){if(key==='$path')assert(exists('game/'+v),`Missing Rojo source ${v}`);else if(v&&typeof v==='object')walk(v);}};walk(project.tree);
 const catalog=read('assets/catalog.json'), ids=new Set();
 for(const a of catalog.assets){assert(!ids.has(a.id),`Duplicate asset ${a.id}`);ids.add(a.id);assert(catalog.categories.includes(a.category),`Unknown category ${a.id}`);assert(Number.isInteger(a.version)&&a.version>0,`Invalid version ${a.id}`);assert(a.source&&exists(a.source),`Missing source ${a.id}`);assert(a.rights&&a.integration,`Missing rights/integration ${a.id}`);assert(['planned','blockout','proof','implemented','approved','retired'].includes(a.status),`Invalid status ${a.id}`);for(const p of [...a.files,...a.evidence])assert(exists(p),`Missing asset evidence/export ${p}`);if(release&&a.requiredForRelease)assert(a.status==='approved'&&a.evidence.length>0,`Not release-approved ${a.id}`);}
 for(const category of ['characters','environment','props','npcs','ui'])assert(catalog.assets.some(a=>a.category===category),`Uncovered category ${category}`);
 const audio=read('assets/audio/library.json'), cueIds=new Set();for(const c of audio.cues){assert(!cueIds.has(c.id),`Duplicate cue ${c.id}`);cueIds.add(c.id);assert(/^PB_[A-Za-z]+_[A-Za-z]+_v\d{2}$/.test(c.name),`Invalid audio name ${c.id}`);if(c.status==='approved')assert(c.robloxId&&c.rights==='approved'&&c.source,`Unproven approved audio ${c.id}`);}
 const expectedAudio={bird:['WingFlap','Call','TakeOff','Land'],flight:['Wind','FastWind','DiveWind'],poop:['Release','Projectile','Splat','Headshot','Combo','Reward'],environment:['Traffic','CityAmbience','People','Dogs','Nature'],gameplay:['WantedIncrease','Capture','EggHatch','LegendaryHatch','PvPVictory','UIFeedback']};
 for(const [category,cues]of Object.entries(expectedAudio))for(const cue of cues)assert(cueIds.has(`${category}.${cue}`),`Missing requested audio ${category}.${cue}`);
 assert(audio.cues.length===24,'Expected all 24 requested audio cues');
 const vfx=read('assets/vfx/library.json');assert(vfx.effects.length===12,'Missing VFX categories');for(const e of vfx.effects)assert(e.maxActive>0&&e.lifetimeSeconds>0&&e.maxDistanceStuds>0&&!e.awardsGameplay,`Unsafe effect budget/authority ${e.id}`);
 for(const id of ['PoopSplat','Headshot','ScorePopup','Speed','Dive','Wanted','EggHatch','LegendaryReward','PvP','BirdAbility','Trail','Cosmetic'])assert(vfx.effects.some(e=>e.id===id),`Missing requested effect ${id}`);
 const validation=read('assets/characters/pigeon/v1/validation.json'), roundtrip=read('assets/characters/pigeon/v1/export-roundtrip.json');assert(validation.bones===16&&validation.maxInfluences<=4&&validation.unweightedVertices===0&&validation.triangles<=20000,'Pigeon validation failed');assert(roundtrip.passed&&roundtrip.fbx.length===6&&roundtrip.glbAnimations.length===5,'Character export evidence incomplete');
 const server=fs.readFileSync(path.join(root,'game/src/ServerScriptService/GameServer.server.luau'),'utf8');assert(server.includes('DataStoreService:GetDataStore("BirdCity_Player_v1")'),'Production persistence still disabled');
 const gates=read('assets/release-gates.json');if(release)for(const g of gates.gates)assert(g.status==='passed'&&g.evidence&&g.reviewedAt,`Release gate pending ${g.id}`);
 console.log(`Checked ${docs.length} docs, ${catalog.assets.length} assets, ${audio.cues.length} cues, ${vfx.effects.length} effects and ${roundtrip.fbx.length} FBX reports.`);
 console.log(release?'Release audit requested':'Development workflow audit; no runtime/release claims');
}catch(e){errors.push(e.message);}
for(const e of errors)console.error('FAIL:',e);
if(errors.length)process.exitCode=1;else console.log('PASS');
