-- Studs, centered on the city. Bird dimensions and flight balance stay unchanged.
local World = {
	Version = 2,
	Width = 1640,
	GroundY = 0,
	HubCenter = Vector3.new(0, 400, 0),
	HubSize = Vector3.new(540, 12, 420),
	SpawnPosition = Vector3.new(0, 406, 148),
	ReturnCooldown = 20,
	ReturnCombatLock = 10,
	ReturnChannel = 2,
	Population = { CitizenCap = 24, DogCap = 6, ActivationRange = 330, DespawnRange = 460, UpdateInterval = 2 },
	DistrictOrder = { "Downtown", "Residential", "Commercial", "Park", "Industrial", "Outskirts" },
	Districts = {
		Downtown = { Center = Vector3.new(0, 0, -260), Size = Vector2.new(520, 520), Color = Color3.fromRGB(78, 155, 205), Citizens = 8, Dogs = 0 },
		Residential = { Center = Vector3.new(-550, 0, -260), Size = Vector2.new(480, 560), Color = Color3.fromRGB(240, 175, 105), Citizens = 5, Dogs = 2 },
		Commercial = { Center = Vector3.new(550, 0, -260), Size = Vector2.new(480, 520), Color = Color3.fromRGB(236, 120, 107), Citizens = 8, Dogs = 1 },
		Park = { Center = Vector3.new(-480, 0, 400), Size = Vector2.new(600, 600), Color = Color3.fromRGB(90, 181, 110), Citizens = 5, Dogs = 2 },
		Industrial = { Center = Vector3.new(480, 0, 390), Size = Vector2.new(600, 560), Color = Color3.fromRGB(135, 153, 163), Citizens = 4, Dogs = 1 },
		Outskirts = { Center = Vector3.new(0, 0, 720), Size = Vector2.new(1640, 180), Color = Color3.fromRGB(128, 170, 117), Citizens = 2, Dogs = 0 },
	},
}
function World.GetDistrict(position)
	for _, name in ipairs(World.DistrictOrder) do
		local d = World.Districts[name]
		if math.abs(position.X-d.Center.X) <= d.Size.X/2 and math.abs(position.Z-d.Center.Z) <= d.Size.Y/2 then return name end
	end
	return "Outskirts"
end
function World.IsHub(position)
	return position.Y >= 360 and math.abs(position.X) < 490 and math.abs(position.Z) < 240
end
return World
