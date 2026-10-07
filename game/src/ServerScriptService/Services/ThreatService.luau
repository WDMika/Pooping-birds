local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Config = require(game.ReplicatedStorage.Shared.Config)
local WorldConfig = require(game.ReplicatedStorage.Shared.WorldConfig)
local ThreatService = {}

local function nearest(root, predicate, range)
	local target, distance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if hrp and humanoid and humanoid.Health > 0 and not WorldConfig.IsHub(hrp.Position) and not player:GetAttribute("Captured") and predicate(player, hrp) then
			local d = (hrp.Position - root.Position).Magnitude
			if d < range and (not distance or d < distance) then target = player; distance = d end
		end
	end
	return target, distance
end

local function lineOfSight(model, target, origin, destination)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	local result = workspace:Raycast(origin, destination - origin, params)
	return not result or result.Instance:IsDescendantOf(target)
end

function ThreatService.StartDog(model, hum, root)
	root:SetNetworkOwner(nil)
	local spec = Config.Threats.Dog
	local lastJump, lastAttack = -math.huge, -math.huge
	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			local target, distance = nearest(root, function(_, hrp)
				return math.abs(hrp.Position.Y - root.Position.Y) <= spec.DetectionHeight
			end, spec.DetectionRange)
			if target then
				local character = target.Character
				local tr = character and character:FindFirstChild("HumanoidRootPart")
				local th = character and character:FindFirstChildOfClass("Humanoid")
				if tr and th then
					local delta = tr.Position - root.Position
					local horizontal = Vector3.new(delta.X, 0, delta.Z)
					hum:MoveTo(Vector3.new(tr.Position.X, root.Position.Y, tr.Position.Z))
					local now = os.clock()
					local visible = lineOfSight(model, character, root.Position, tr.Position)
					if visible and delta.Y > 1 and delta.Y <= spec.JumpHeight and horizontal.Magnitude < spec.JumpRange and now - lastJump >= spec.JumpCooldown then
						-- Explicit velocity also supports the temporary welded NPC rig.
						local direction = horizontal.Magnitude > 0.01 and horizontal.Unit or Vector3.zero
						hum:ChangeState(Enum.HumanoidStateType.Physics)
						task.wait() -- Apply the state before velocity; otherwise the rig cancels the impulse.
						if not root.Parent then break end
						root.AssemblyLinearVelocity = direction * spec.JumpForwardSpeed + Vector3.yAxis * spec.JumpSpeed
						task.delay(0.55, function()
							if hum.Parent and hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Running) end
						end)
						model:SetAttribute("LastJump", now)
						lastJump = now
					end
					if visible and distance <= spec.AttackRange and math.abs(delta.Y) <= spec.AttackHeight and now - lastAttack >= spec.AttackCooldown then
						lastAttack = now
						th:TakeDamage(spec.Damage)
						target:SetAttribute("LastThreatDamageAt", now)
					end
				end
			else hum:MoveTo(root.Position) end
			task.wait(0.25)
		end
	end)
end

function ThreatService.StartCatcher(model, hum, root, feedback)
	root:SetNetworkOwner(nil)
	local spec = Config.Threats.AnimalControl
	local lastNet = -math.huge
	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			local target, distance = nearest(root, function(p) return (p:GetAttribute("Wanted") or 0) > 0 end, spec.DetectionRange)
			if target then
				local character = target.Character
				local tr = character and character:FindFirstChild("HumanoidRootPart")
				if tr then
					local stars = math.clamp(target:GetAttribute("Wanted") or 1, 1, 5)
					hum.WalkSpeed = spec.BaseSpeed + stars * spec.SpeedPerStar
					hum:MoveTo(Vector3.new(tr.Position.X, root.Position.Y, tr.Position.Z))
					if stars >= spec.NetMinimumStars and distance < spec.NetRange + stars * spec.RangePerStar and math.abs(tr.Position.Y - root.Position.Y) < spec.NetHeight and os.clock() - lastNet >= spec.NetCooldown then
						lastNet = os.clock()
						model:SetAttribute("Aiming", true)
						feedback:FireClient(target, "Toast", "Bird Catcher aiming! Fly away or climb!")
						-- Telegraph the aim, then a visible net travels toward the sampled position.
						task.wait(spec.AimTime)
						model:SetAttribute("Aiming", false)
						if target.Character == character and tr.Parent and not target:GetAttribute("Captured") then
							local origin = root.Position + Vector3.new(0, 2, 0)
							local destination = tr.Position
							if lineOfSight(model, character, origin, destination) then
								local net = Instance.new("Part")
								net.Name = "CaptureNet"
								net.Shape = Enum.PartType.Ball
								net.Size = Vector3.new(3, 3, 3)
								net.Color = Color3.fromRGB(100, 220, 190)
								net.Transparency = 0.55
								net.Anchored = true
								net.CanCollide = false; net.CanTouch = false; net.CanQuery = false
								net.Parent = workspace.BirdCity.Effects
								Debris:AddItem(net, 2)
								local duration = math.max(0.15, (destination - origin).Magnitude / spec.NetSpeed)
								local started = os.clock()
								while net.Parent and os.clock() - started < duration do
									net.Position = origin:Lerp(destination, math.clamp((os.clock() - started) / duration, 0, 1))
									task.wait(0.03)
								end
								if net.Parent then net:Destroy() end
								local th = character:FindFirstChildOfClass("Humanoid")
								if target.Character == character and tr.Parent and th and th.Health > 0 and not target:GetAttribute("Captured") and (tr.Position - destination).Magnitude < spec.CaptureRadius and lineOfSight(model, character, origin, tr.Position) then
									target:SetAttribute("Captured", true)
									tr.Anchored = true
									feedback:FireClient(target, "Defeat", "Caught by Animal Control! Returning to the roost…")
									task.delay(spec.TrapTime, function()
										if tr.Parent then tr.Anchored = false end
										if target.Parent and target.Character == character and th.Health > 0 then th.Health = 0 end
									end)
								end
							end
						end
					end
				end
			else hum.WalkSpeed = spec.BaseSpeed; hum:MoveTo(root.Position) end
			task.wait(0.35)
		end
	end)
end

return ThreatService
