-- Studio tooling: generates editable KeyframeSequences against an imported rig's bind pose.
-- Runtime playback uses published animation IDs or the proof pose bridge, never temporary IDs.
local Config = require(script.Parent.BirdAnimationConfig)
local Proof = require(script.Parent.BirdProofClips)
local Builder = {}
function Builder.Build(model, clipName)
	local clip = assert(Proof.clips[clipName], "Unknown proof clip")
	local mesh = assert(model.PrimaryPart, "Rig requires a PrimaryPart")
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = clipName; sequence.Loop = clip.loop; sequence.Priority = Enum.AnimationPriority.Movement
	local function quaternion(q) return CFrame.new(0,0,0,q[2],q[3],q[4],q[1]) end
	for _, sample in clip.samples do
		local key = Instance.new("Keyframe"); key.Time = sample.time; key.Parent = sequence
		local meshPose = Instance.new("Pose"); meshPose.Name = mesh.Name; meshPose.Weight = 0; meshPose.Parent = key
		local poses, rotations = {}, {}
		for _, name in Config.Bones do
			local bone = assert(model:FindFirstChild(name, true), "Missing bone " .. name)
			local parent = bone.Parent
			local target = mesh.CFrame.Rotation * quaternion(sample.rotations[name]) * mesh.CFrame.Rotation:Inverse() * bone.WorldCFrame.Rotation
			local parentRotation = parent:IsA("Bone") and rotations[parent.Name] or parent.CFrame.Rotation
			local pose = Instance.new("Pose"); pose.Name = name; pose.Weight = 1
			pose.CFrame = bone.CFrame.Rotation:Inverse() * parentRotation:Inverse() * target
			pose.EasingStyle = Enum.PoseEasingStyle.Linear
			pose.Parent = parent:IsA("Bone") and poses[parent.Name] or meshPose
			poses[name] = pose; rotations[name] = target
		end
		if sample.time == 0 or (not clip.loop and sample.time == clip.duration) then
			local marker = Instance.new("KeyframeMarker"); marker.Name = sample.time == 0 and "Start" or "Complete"; marker.Parent = key
		end
	end
	return sequence
end
return Builder
