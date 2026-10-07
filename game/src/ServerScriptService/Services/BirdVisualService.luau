local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.Shared.BirdAnimationConfig)
local Service = {}
function Service.Mount(character, species, root)
	local folder = ServerStorage:FindFirstChild("BirdCharacterTemplates")
	local template = folder and folder:FindFirstChild(species)
	if not template then return nil end
	if not template:IsA("Model") or template:GetAttribute("RigVersion") ~= Config.RigVersion then warn("Bird template has incompatible rig: " .. species); return nil end
	for _, name in Config.Bones do
		local bone = template:FindFirstChild(name, true)
		if not bone or not bone:IsA("Bone") then warn("Bird template missing bone: " .. name); return nil end
	end
	local visual = template:Clone()
	for _, name in {"AnimSaves", "InitialPoses"} do local authoring = visual:FindFirstChild(name); if authoring then authoring:Destroy() end end
	visual.Name = "BirdVisual"
	local mesh = visual:FindFirstChildWhichIsA("MeshPart", true)
	visual.PrimaryPart = mesh
	local origin = mesh:FindFirstChild("Root")
	mesh.PivotOffset = origin.CFrame
	local speciesConfig = Config.Species[species]
	visual:PivotTo(root.CFrame * (speciesConfig and speciesConfig.VisualOffset or CFrame.new(0, -1.7, 0)))
	for _, item in visual:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = false; item.CanCollide = false; item.CanTouch = false; item.CanQuery = false; item.Massless = true
			local weld = Instance.new("WeldConstraint"); weld.Part0 = root; weld.Part1 = item; weld.Parent = item
		elseif item:IsA("Bone") then item.Transform = CFrame.identity end
	end
	local controller = visual:FindFirstChildOfClass("AnimationController") or Instance.new("AnimationController", visual)
	controller.Name = "AnimationController"
	local animator = controller:FindFirstChildOfClass("Animator") or Instance.new("Animator", controller)
	animator.Name = "Animator"
	visual:SetAttribute("Species", species)
	visual.Parent = character
	return visual
end
function Service.Signal(character, name)
	character:SetAttribute("BirdAnimationAction", name)
	character:SetAttribute("BirdAnimationActionSerial", (character:GetAttribute("BirdAnimationActionSerial") or 0) + 1)
end
return Service
