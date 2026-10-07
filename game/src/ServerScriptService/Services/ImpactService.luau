-- Replaceable, bounded impact visuals and positional audio. No gameplay rewards here.
local Debris = game:GetService("Debris")
local Config = require(game.ReplicatedStorage.Shared.Config)
local ImpactService = {}

function ImpactService.PlaySound(cue, parent)
	local spec = Config.Audio[cue]
	if not spec or spec.SoundId == "" or not parent then return end
	local sound = Instance.new("Sound")
	sound.Name = "BirdAudio_" .. cue
	sound.SoundId = spec.SoundId
	sound.Volume = spec.Volume
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = spec.Range or 70
	sound.Looped = spec.Looped == true
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, spec.Lifetime or 8)
	return sound
end

function ImpactService.Splat(hit, position, normal, effects)
	if not hit or not hit.Parent then return end
	local existing = effects:GetChildren()
	if #existing >= Config.Poop.MaxSplats then existing[1]:Destroy() end
	local splat = Instance.new("Part")
	splat.Name = "PoopSplat"
	splat.Shape = Enum.PartType.Ball
	splat.Size = Vector3.new(1.6, 1.3, 0.12)
	splat.Color = Color3.fromRGB(245, 245, 222)
	splat.Material = Enum.Material.SmoothPlastic
	splat.CanCollide = false
	splat.CanTouch = false
	splat.CanQuery = false
	splat.Massless = true
	normal = normal.Magnitude > 0.001 and normal.Unit or Vector3.yAxis
	splat.CFrame = CFrame.lookAt(position + normal * 0.08, position + normal)
	splat.Anchored = not hit:IsA("BasePart") or hit.Anchored
	splat.Parent = effects
	if hit:IsA("BasePart") then
		-- Keep the NPC assembly free to move. The weld disappears with this effect.
		splat.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hit
		weld.Part1 = splat
		weld.Parent = splat
	end
	ImpactService.PlaySound("Impact", splat)
	Debris:AddItem(splat, Config.Poop.SplatLifetime)
	return splat
end

return ImpactService
