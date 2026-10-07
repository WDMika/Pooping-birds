-- Client input and flight controller. Game rewards, purchases and hits stay server-authored.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
player.CameraMode = Enum.CameraMode.Classic
player.CameraMinZoomDistance = 10
player.CameraMaxZoomDistance = 32
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("BirdRemotes")
local action = remotes:WaitForChild("Action")
local feedback = remotes:WaitForChild("Feedback")
local UIController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("UIController"))
local interface = UIController.new(Config, action, feedback, player)
local BirdAnimationController = require(script.Parent.Controllers.BirdAnimationController)
local animationControllers = {}
local animationInput = {Flapping = false, Boost = false}
-- Own movement intent is immediate; other birds derive presentation from replicated velocity.
RunService.PreSimulation:Connect(function(dt)
	for char, controller in animationControllers do
		if not char.Parent or char:FindFirstChild("BirdVisual") ~= controller.Visual then controller:Destroy(); animationControllers[char] = nil end
	end
	for _, observer in Players:GetPlayers() do
		local char = observer.Character
		local visual = char and char:FindFirstChild("BirdVisual")
		local birdRoot = char and char:FindFirstChild("HumanoidRootPart")
		if visual and visual:GetAttribute("RigVersion") == "BirdRig_v1" and birdRoot then
			local controller = animationControllers[char]
			if not controller then controller = BirdAnimationController.new(char, visual); animationControllers[char] = controller end
			local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {char}; params.RespectCanCollide = true
			local hit = workspace:Raycast(birdRoot.Position, Vector3.new(0, -4.2, 0), params)
			local motion = birdRoot.AssemblyLinearVelocity
			local flapping = motion.Magnitude > 4
			local boost = observer:GetAttribute("Boosting") == true
			if observer == player then flapping = animationInput.Flapping; boost = animationInput.Boost end
			controller:Update(dt, {Grounded = hit ~= nil and motion.Y < 3, Speed = motion.Magnitude, VerticalSpeed = motion.Y, Boost = boost, Flapping = flapping, Stunned = observer:GetAttribute("Captured") == true})
		end
	end
end)

local function new(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	object.Parent = parent
	return object
end

local function requestPoop()
	if interface:CanPoop() then action:FireServer("Poop") end
end
interface.OnPoop = requestPoop

local function poopAction(_, state)
	if state == Enum.UserInputState.Begin then requestPoop() end
	return Enum.ContextActionResult.Sink
end
-- The custom HUD button is the touch action; this binding only routes keyboard/controller input.
ContextActionService:BindAction("BirdPoop", poopAction, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonR2)

local keys = {}
local function bindTouchAction(name, title, key, position, alternateKey)
	ContextActionService:BindAction(name, function(_, state)
		if state == Enum.UserInputState.Begin then
			keys[key] = true
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			keys[key] = nil
		end
		return Enum.ContextActionResult.Sink
	end, true, key, alternateKey)
	ContextActionService:SetTitle(name, title)
	ContextActionService:SetPosition(name, position)
end
bindTouchAction("BirdClimbTouch", "UP", Enum.KeyCode.Space, UDim2.new(0.7, 0, 0.55, 0), Enum.KeyCode.ButtonA)
bindTouchAction("BirdDiveTouch", "DIVE", Enum.KeyCode.LeftControl, UDim2.new(0.7, 0, 0.78, 0), Enum.KeyCode.ButtonB)
bindTouchAction("BirdBoostTouch", "BOOST", Enum.KeyCode.LeftShift, UDim2.new(0.9, 0, 0.55, 0), Enum.KeyCode.ButtonL1)

local character, root, humanoid, attachment, linear, align
local velocity = Vector3.zero
local function setupFlight(char)
	character = char
	root = char:WaitForChild("HumanoidRootPart")
	humanoid = char:WaitForChild("Humanoid")
	local old = root:FindFirstChild("BirdFlightAttachment")
	if old then old:Destroy() end
	attachment = new("Attachment", { Name = "BirdFlightAttachment" }, root)
	linear = new("LinearVelocity", {
		Name = "BirdFlightVelocity",
		Attachment0 = attachment,
		RelativeTo = Enum.ActuatorRelativeTo.World,
		MaxForce = 1e6,
		VectorVelocity = Vector3.zero,
	}, root)
	align = new("AlignOrientation", {
		Name = "BirdFlightFacing",
		Attachment0 = attachment,
		Mode = Enum.OrientationAlignmentMode.OneAttachment,
		Responsiveness = 16,
		MaxTorque = 1e6,
		MaxAngularVelocity = 18,
	}, root)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	velocity = root.AssemblyLinearVelocity
end
feedback.OnClientEvent:Connect(function(kind)
	if kind=="FlightReset" then velocity=Vector3.zero;if linear and linear.Parent then linear.VectorVelocity=Vector3.zero end end
end)
ContextActionService:BindAction("ReturnNest",function(_,state) if state==Enum.UserInputState.Begin then action:FireServer("ReturnToHub") end;return Enum.ContextActionResult.Sink end,false,Enum.KeyCode.H,Enum.KeyCode.ButtonY)
player.CharacterAdded:Connect(setupFlight)
if player.Character then task.spawn(setupFlight, player.Character) end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed then keys[input.KeyCode] = true end
end)
UserInputService.InputEnded:Connect(function(input)
	keys[input.KeyCode] = nil
end)

local function isDown(key)
	return keys[key] == true
end

local boostSent = false
RunService.RenderStepped:Connect(function(dt)
	if interface:IsBlockingInput() or not root or not root.Parent or not linear or not linear.Parent then
		animationInput.Flapping = false; animationInput.Boost = false
		velocity=Vector3.zero; if linear and linear.Parent then linear.VectorVelocity=Vector3.zero end
		if boostSent then
			boostSent = false
			action:FireServer("Boost", false)
		end
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local bird = Config.Birds[player:GetAttribute("EquippedBird") or "Pigeon"] or Config.Birds.Pigeon
	local speedUpgrade = tonumber(player:GetAttribute("Upgrade_FlightSpeed")) or 0
	local look = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector
	local forward = (isDown(Enum.KeyCode.W) and 1 or 0) - (isDown(Enum.KeyCode.S) and 1 or 0)
	local side = (isDown(Enum.KeyCode.D) and 1 or 0) - (isDown(Enum.KeyCode.A) and 1 or 0)
	local vertical = (isDown(Enum.KeyCode.Space) and 1 or 0) - (isDown(Enum.KeyCode.LeftControl) and 1 or 0)
	local mobileMove = humanoid and humanoid.MoveDirection or Vector3.zero
	local move = look * forward + right * side + Vector3.new(0, vertical, 0)
	if move.Magnitude < 0.15 then move = Vector3.new(mobileMove.X, vertical, mobileMove.Z) end
	local boost = isDown(Enum.KeyCode.LeftShift) or isDown(Enum.KeyCode.RightShift) or isDown(Enum.KeyCode.ButtonL1)
	local stamina = player:GetAttribute("Stamina") or 100
	local speed = bird.FlightSpeed * (1 + speedUpgrade * Config.Upgrades.FlightSpeed.Step) * (boost and stamina > 1 and 1.55 or 1) * (((player:GetAttribute("Thirst") or 100) < 15) and 0.75 or 1)
	if move.Magnitude > 1 then move = move.Unit end
	local target = move * speed
	if move.Magnitude < 0.08 then target = Vector3.new(velocity.X * 0.92, 0, velocity.Z * 0.92) end
	velocity = velocity:Lerp(target, math.clamp(dt * bird.Acceleration, 0, 1))
	linear.VectorVelocity = velocity
	local face = Vector3.new(look.X, math.clamp(look.Y, -0.5, 0.65), look.Z)
	if face.Magnitude > 0.1 then align.CFrame = CFrame.lookAt(Vector3.zero, face.Unit) * CFrame.Angles(-0.18, 0, side * 0.12) end
	local shouldBoost = boost and move.Magnitude > 0.1 and stamina > 0
	animationInput.Flapping = move.Magnitude > 0.08
	animationInput.Boost = shouldBoost
	if shouldBoost ~= boostSent then
		boostSent = shouldBoost
		action:FireServer("Boost", boostSent)
	end
end)
