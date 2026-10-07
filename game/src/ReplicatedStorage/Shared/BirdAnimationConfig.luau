-- Published IDs belong to the experience owner. Empty IDs use the local proof pose library.
local Config = {}
Config.RigVersion = "BirdRig_v1"
Config.StudioPreview = true
Config.Bones = {"Root", "Body", "Chest", "Neck", "Head", "Wing_L_Upper", "Wing_L_Mid", "Wing_L_Tip", "Wing_R_Upper", "Wing_R_Mid", "Wing_R_Tip", "Tail", "Leg_L", "Foot_L", "Leg_R", "Foot_R"}
Config.SharedIds = {Idle = "", TakeOff = "", Fly = "", Glide = "", Land = ""}
Config.Species = {Pigeon = {Ids = {}, VisualOffset = CFrame.new(0, -3.8, 0)}}
Config.Fallbacks = {FastFly = "Fly", Dive = "Glide", Brake = "Glide", TurnLeft = "Fly", TurnRight = "Fly", Walk = "Idle", Hop = "Idle", Stunned = "Idle", Sleep = "Idle", Death = "Idle"}
Config.Actions = {Poop = 0.45, Hit = 0.25, Attack = 0.4, Eat = 0.8, Drink = 0.8}
Config.Loops = {Idle = true, Fly = true, Glide = true, FastFly = true, Dive = true, Brake = true, TurnLeft = true, TurnRight = true, Sleep = true, Stunned = true}
function Config.Resolve(species, state)
	local overrides = Config.Species[species]
	local ids = overrides and overrides.Ids or {}
	local id = ids[state] or Config.SharedIds[state]
	local clip = state
	if not id or id == "" then clip = Config.Fallbacks[state] or state; id = ids[clip] or Config.SharedIds[clip] end
	return clip, id and id ~= "" and id or nil, state == "FastFly" and 1.35 or 1
end
return Config
