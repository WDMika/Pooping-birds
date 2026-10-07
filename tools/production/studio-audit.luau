-- Read-only Edit-mode audit. Return JSON through Studio MCP or print in Command Bar.
local CollectionService = game:GetService("CollectionService")
local world = workspace:FindFirstChild("BirdCity")
local result = {PlaceId = game.PlaceId, StreamingEnabled = workspace.StreamingEnabled, World = {}, Tags = {}, Templates = {}}
if world then
	result.WorldVersion = world:GetAttribute("WorldVersion")
	for _, folder in world:GetChildren() do result.World[folder.Name] = #folder:GetDescendants() end
end
for _, tag in {"FoodSpawn", "WaterSpawn", "NPCSpawn", "DogSpawn", "AnimalControlSpawn", "ReturnToHub", "HubInteraction", "FlightLaunch"} do
	local count = 0
	for _, marker in CollectionService:GetTagged(tag) do if world and marker:IsDescendantOf(world) then count += 1 end end
	result.Tags[tag] = count
end
local templates = game.ServerStorage:FindFirstChild("BirdCharacterTemplates")
if templates then for _, model in templates:GetChildren() do
	local bones = 0
	for _, object in model:GetDescendants() do if object:IsA("Bone") then bones += 1 end end
	result.Templates[model.Name] = {RigVersion=model:GetAttribute("RigVersion"), Bones=bones}
end end
return game:GetService("HttpService"):JSONEncode(result)
