-- Client presentation. Keys come from the audio library; rewards never come from sounds.
local SoundService = game:GetService("SoundService")
local Definitions = require(game.ReplicatedStorage.Shared.ContentDefinitions).Audio
local Audio = {}
Audio.__index = Audio
function Audio.new()
	local self = setmetatable({Voices = {}, Loops = {}, Count = 0, Destroyed = false, Groups = {}}, Audio)
	for _, name in {"PB_Master", "PB_SFX", "PB_Ambience", "PB_UI"} do
		local group = SoundService:FindFirstChild(name) or Instance.new("SoundGroup")
		group.Name = name; group.Parent = name == "PB_Master" and SoundService or self.Groups.PB_Master
		self.Groups[name] = group
	end
	return self
end
function Audio:SetVolume(bus, value)
	if self.Groups[bus] and type(value) == "number" then self.Groups[bus].Volume = math.clamp(value, 0, 1) end
end
function Audio:_Stop(sound)
	local record = self.Voices[sound]
	if not record then return end
	self.Voices[sound] = nil; self.Count -= 1
	if record.LoopKey then self.Loops[record.LoopKey] = nil end
	for _, connection in record.Connections do connection:Disconnect() end
	sound:Destroy()
end
function Audio:StopLoop(key)
	local sound = self.Loops[key]
	if sound then self:_Stop(sound) end
end
function Audio:Play(cue, parent, loopKey)
	local spec = Definitions[cue]
	if self.Destroyed or not spec or spec.SoundId == "" then return nil, "unassigned cue" end
	if spec.Looped and (type(loopKey) ~= "string" or #loopKey > 64) then return nil, "loop requires a stop key" end
	if spec.Looped and self.Loops[loopKey] then
		local old = self.Loops[loopKey]
		if self.Voices[old].Cue == cue then return old end
		self:_Stop(old)
	end
	if spec.Looped then
		local count = 0
		for _, record in self.Voices do
			if record.LoopKey and ((spec.Bus == "PB_Ambience" and record.Bus == spec.Bus) or (string.sub(cue,1,7) == "flight." and record.Parent == parent and string.sub(record.Cue,1,7) == "flight.")) then count += 1 end
		end
		if (spec.Bus == "PB_Ambience" and count >= 4) or (string.sub(cue,1,7) == "flight." and count >= 2) then return nil, "loop budget" end
	end
	if self.Count >= 48 then return nil, "voice budget" end
	if spec.Bus ~= "PB_UI" and (not parent or not (parent:IsA("BasePart") or parent:IsA("Attachment")) or not parent:IsDescendantOf(workspace)) then return nil, "positional parent required" end
	local sound = Instance.new("Sound")
	sound.Name = spec.Name; sound.SoundId = spec.SoundId; sound.Volume = spec.Volume
	sound.Looped = spec.Looped; sound.RollOffMinDistance = 8; sound.RollOffMaxDistance = spec.Range
	sound.SoundGroup = self.Groups[spec.Bus]; sound.Parent = spec.Bus == "PB_UI" and SoundService or parent
	local record = {Connections = {}, LoopKey = spec.Looped and loopKey or nil, Cue = cue, Bus = spec.Bus, Parent = parent}
	self.Voices[sound] = record; self.Count += 1
	if spec.Looped then self.Loops[loopKey] = sound end
	record.Connections[1] = sound.Ended:Connect(function() self:_Stop(sound) end)
	record.Connections[2] = sound.AncestryChanged:Connect(function() if not sound:IsDescendantOf(game) then self:_Stop(sound) end end)
	if not spec.Looped then task.delay(spec.Lifetime, function() self:_Stop(sound) end) end
	sound:Play()
	return sound
end
function Audio:Destroy()
	self.Destroyed = true
	local voices = {}; for sound in self.Voices do table.insert(voices, sound) end
	for _, sound in voices do self:_Stop(sound) end
end
return Audio
