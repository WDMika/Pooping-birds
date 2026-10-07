local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.BirdAnimationConfig)
local State = require(Shared.BirdAnimationState)
local Proof = require(Shared.BirdProofClips)
local Controller = {}
Controller.__index = Controller
function Controller.new(character, visual)
	local self = setmetatable({Character = character, Visual = visual, Machine = State.new(), Tracks = {}, Bones = {}, Connections = {}, CurrentTrack = nil, LastHealth = nil}, Controller)
	self.Animator = visual.AnimationController:FindFirstChildOfClass("Animator")
	self.PreviewIds = {}
	if Config.StudioPreview and game:GetService("RunService"):IsStudio() and character == Players.LocalPlayer.Character then
		local builder = require(Shared.BirdAnimationSequenceBuilder)
		for name in Proof.clips do
			local sequence = builder.Build(visual, name)
			local ok, id = pcall(function() return game:GetService("AnimationClipProvider"):RegisterAnimationClip(sequence) end)
			sequence:Destroy()
			if ok then self.PreviewIds[name] = id else warn("Studio bird preview unavailable: " .. tostring(id)) end
		end
	end
	for _, name in Config.Bones do self.Bones[name] = visual:FindFirstChild(name, true) end
	self.Connections[1] = character:GetAttributeChangedSignal("BirdAnimationActionSerial"):Connect(function()
		local name = character:GetAttribute("BirdAnimationAction")
		if Config.Actions[name] then self.Machine:Signal(name, Config.Actions[name]) end
	end)
	return self
end
function Controller:Destroy()
	for _, connection in self.Connections do connection:Disconnect() end
	for _, track in self.Tracks do if track then track:Stop(0); track:Destroy() end end
	for _, bone in self.Bones do if bone and bone.Parent then bone.Transform = CFrame.identity end end
end
function Controller:Update(dt, input)
	local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if self.LastHealth and humanoid.Health < self.LastHealth then self.Machine:Signal("Hit", Config.Actions.Hit) end
		self.LastHealth = humanoid.Health; input.Dead = humanoid.Health <= 0
	end
	input.Stunned = input.Stunned or self.Character:GetAttribute("Captured") == true
	local state, age = self.Machine:Update(dt, input)
	local clipName, id, speed = Config.Resolve(self.Visual:GetAttribute("Species"), state)
	id = id or self.PreviewIds[clipName]
	self.Visual:SetAttribute("AnimationState", state)
	if id and self.Animator then
		-- Only the owning player's client starts replicated character tracks.
		if self.Character ~= Players.LocalPlayer.Character then return end
		local track = self.Tracks[id]
		if track == false then id = nil
		elseif not track then
			local animation = Instance.new("Animation"); animation.AnimationId = id
			local ok, loaded = pcall(self.Animator.LoadAnimation, self.Animator, animation); animation:Destroy()
			if ok then track = loaded; self.Tracks[id] = track else self.Tracks[id] = false; id = nil; warn("Bird animation failed: " .. tostring(loaded)) end
		end
		if id then
			if track ~= self.CurrentTrack then
				if self.CurrentTrack then self.CurrentTrack:Stop(0.12) end
				for _, bone in self.Bones do bone.Transform = CFrame.identity end
				track.Looped = Config.Loops[state] == true
				track.Priority = Config.Actions[state] and Enum.AnimationPriority.Action or Enum.AnimationPriority.Movement
				track:Play(0.12, 1, speed); self.CurrentTrack = track
			end
			track:AdjustSpeed(speed)
			self.Visual:SetAttribute("PlaybackMode", "Animator")
			return
		end
	end
	if self.CurrentTrack then self.CurrentTrack:Stop(0.12); self.CurrentTrack = nil end
	-- Authoring bridge until owner-published IDs are assigned. Each observing client poses its replica.
	local clip = Proof.clips[clipName]
	if not clip then clip = Proof.clips[input.Grounded and "Idle" or "Fly"] end
	self.Visual:SetAttribute("PlaybackMode", "ProofPose")
	local t = clip.loop and (age * speed % clip.duration) or math.min(age * speed, clip.duration)
	local index = math.min(math.floor(t * 30) + 1, #clip.samples)
	local a, b = clip.samples[index], clip.samples[math.min(index + 1, #clip.samples)]
	local alpha = math.clamp((t - a.time) * 30, 0, 1)
	local mesh = self.Visual.PrimaryPart
	local worldRotations = {}
	local function quaternion(q) return CFrame.new(0, 0, 0, q[2], q[3], q[4], q[1]) end
	for _, name in Config.Bones do
		local bone = self.Bones[name]
		local parent = bone.Parent
		local bindWorld = bone.WorldCFrame.Rotation
		local delta = quaternion(a.rotations[name]):Lerp(quaternion(b.rotations[name]), alpha)
		local meshRotation = mesh.CFrame.Rotation
		local target = meshRotation * delta * meshRotation:Inverse() * bindWorld
		local parentRotation = parent:IsA("Bone") and worldRotations[parent.Name] or parent.CFrame.Rotation
		local desired = bone.CFrame.Rotation:Inverse() * parentRotation:Inverse() * target
		bone.Transform = bone.Transform:Lerp(desired, math.clamp(dt * 18, 0, 1))
		worldRotations[name] = parentRotation * bone.CFrame.Rotation * bone.Transform.Rotation
	end
end
return Controller
