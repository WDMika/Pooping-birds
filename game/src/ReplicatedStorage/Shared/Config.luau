local Config = {}

Config.Birds = {
	Pigeon = { DisplayName = "Pigeon", Rarity = "Common", Cost = 0, Speed = 1, Stamina = 1, Health = 100, Cooldown = 1.5, Color = Color3.fromRGB(110, 120, 140) },
	Raven = { DisplayName = "Raven", Rarity = "Uncommon", Cost = 250, Speed = 1.1, Stamina = 1.1, Health = 105, Cooldown = 1.35, Color = Color3.fromRGB(45, 50, 65) },
	Seagull = { DisplayName = "Seagull", Rarity = "Rare", Cost = 550, Speed = 1.18, Stamina = 1.15, Health = 110, Cooldown = 1.3, Color = Color3.fromRGB(225, 233, 240) },
	Owl = { DisplayName = "Owl", Rarity = "Rare", Cost = 700, Speed = 1.12, Stamina = 1.25, Health = 115, Cooldown = 1.4, Color = Color3.fromRGB(180, 145, 100) },
	Falcon = { DisplayName = "Falcon", Rarity = "Epic", Cost = 1500, Speed = 1.35, Stamina = 1.2, Health = 100, Cooldown = 1.1, Color = Color3.fromRGB(185, 195, 205) },
	Eagle = { DisplayName = "Eagle", Rarity = "HighTier", Cost = 3000, Speed = 1.5, Stamina = 1.35, Health = 125, Cooldown = 1.25, Color = Color3.fromRGB(120, 85, 55) },
	Phoenix = { DisplayName = "Phoenix", Rarity = "Legendary", Cost = 0, PremiumPlaceholder = true, Speed = 1.6, Stamina = 1.5, Health = 130, Cooldown = 1, Color = Color3.fromRGB(255, 105, 30) },
}

Config.BirdOrder = { "Pigeon", "Raven", "Seagull", "Owl", "Falcon", "Eagle", "Phoenix" }
local powers = { Pigeon = 10, Raven = 18, Seagull = 25, Owl = 28, Falcon = 45, Eagle = 65, Phoenix = 100 }
for name, bird in pairs(Config.Birds) do
	-- Existing clients keep compatibility; all new features use these explicit stats.
	bird.UnlockCost = bird.Cost
	bird.FlightSpeed = 68 * bird.Speed
	bird.Acceleration = 2.6
	bird.PoopCooldown = bird.Cooldown
	bird.BodyPower = powers[name]
	bird.Hunger = 100
	bird.Thirst = 100
	bird.AttackPower = powers[name]
	bird.Defense = 0
	bird.Agility = bird.Speed
	bird.CarryWeight = 1
	bird.Breeding = { Enabled = false, Species = name }
	bird.ProgressionZone = (name == "Pigeon" or name == "Raven" or name == "Seagull" or name == "Owl") and "StarterCity" or "Wilderness"
end
Config.Zones = { StarterCity = { Safeish = true, PvP = false }, Wilderness = { Available = false, PvP = false } }
Config.Poop = { SplatLifetime = 7, MaxSplats = 80, ProjectileLifetime = 10 }
Config.Threats = {
	Dog = { DetectionRange = 75, DetectionHeight = 16, JumpHeight = 10, JumpRange = 16, JumpCooldown = 2.4, JumpSpeed = 38, JumpForwardSpeed = 12, AttackRange = 5, AttackHeight = 4, AttackCooldown = 2.2, Damage = 5 },
	AnimalControl = { DetectionRange = 220, BaseSpeed = 10, SpeedPerStar = 2, NetMinimumStars = 2, NetRange = 18, RangePerStar = 3, NetHeight = 18, NetCooldown = 5, AimTime = 0.8, NetSpeed = 45, CaptureRadius = 4, TrapTime = 2 },
}
-- Supply permitted Roblox audio IDs here. Empty IDs intentionally produce no sound.
Config.Audio = {
	Release = { SoundId = "", Volume = 0.45 },
	Projectile = { SoundId = "", Volume = 0.15, Looped = true, Lifetime = 10 },
	Impact = { SoundId = "", Volume = 0.5 },
	TargetHit = { SoundId = "", Volume = 0.45 },
	Headshot = { SoundId = "", Volume = 0.55 },
}

Config.Food = {
	Burger = { Stat = "Hunger", Amount = 28, Color = Color3.fromRGB(220, 130, 55), Shape = Enum.PartType.Ball },
	Banana = { Stat = "Hunger", Amount = 18, Color = Color3.fromRGB(255, 220, 45), Shape = Enum.PartType.Cylinder },
	Pizza = { Stat = "Hunger", Amount = 24, Color = Color3.fromRGB(235, 85, 55), Shape = Enum.PartType.Block },
	Water = { Stat = "Thirst", Amount = 32, Color = Color3.fromRGB(70, 175, 255), Shape = Enum.PartType.Cylinder },
	Soda = { Stat = "Thirst", Amount = 22, Color = Color3.fromRGB(125, 75, 220), Shape = Enum.PartType.Cylinder },
}

Config.Scoring = {
	BaseHit = 10,
	HeadshotBonus = 15,
	Tiers = { { Height = 10, Multiplier = 1 }, { Height = 25, Multiplier = 1.5 }, { Height = 50, Multiplier = 2 }, { Height = 100, Multiplier = 3 }, { Height = math.huge, Multiplier = 5 } },
	WantedPerHit = 1,
}

Config.Survival = { HungerDrain = 0.08, ThirstDrain = 0.12, StaminaDrain = 7, StaminaRegen = 12, LowThreshold = 15 }
Config.City = { CitizenCount = 14, BuildingCount = 22, FoodCount = 18 }

Config.Upgrades = {
	FlightSpeed = { DisplayName = "Flight Speed", MaxLevel = 5, Costs = { 50, 100, 200, 400, 800 }, Step = 0.05 },
	Stamina = { DisplayName = "Stamina", MaxLevel = 5, Costs = { 50, 100, 200, 400, 800 }, DrainStep = 0.08, RegenStep = 0.10 },
	Health = { DisplayName = "Health", MaxLevel = 5, Costs = { 50, 100, 200, 400, 800 }, Step = 10 },
	PoopCooldown = { DisplayName = "Poop Cooldown", MaxLevel = 5, Costs = { 75, 150, 300, 600, 1200 }, Step = 0.10, Minimum = 0.65 },
	Multiplier = { DisplayName = "Multiplier", MaxLevel = 5, Costs = { 100, 200, 400, 800, 1600 }, Step = 0.25 },
}

Config.DailyRewards = { 50, 75, 100, 125, 150, 200, 300 }

return Config
