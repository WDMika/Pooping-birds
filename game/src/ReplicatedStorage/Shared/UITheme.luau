-- Shared visual tokens for the POOPING BIRDS interface.
local Theme = {}

Theme.Color = {
	Ink = Color3.fromRGB(20, 41, 61),
	InkLight = Color3.fromRGB(31, 59, 79),
	Cream = Color3.fromRGB(255, 247, 219),
	CreamDeep = Color3.fromRGB(229, 240, 217),
	Sky = Color3.fromRGB(107, 199, 232),
	SkyLight = Color3.fromRGB(183, 231, 243),
	Blue = Color3.fromRGB(41, 135, 199),
	Green = Color3.fromRGB(59, 173, 107),
	GreenDark = Color3.fromRGB(39, 135, 84),
	Yellow = Color3.fromRGB(255, 199, 48),
	Orange = Color3.fromRGB(250, 120, 41),
	Coral = Color3.fromRGB(235, 79, 71),
	Muted = Color3.fromRGB(102, 122, 130),
	Track = Color3.fromRGB(209, 219, 212),
	White = Color3.fromRGB(255, 255, 255),
	Overlay = Color3.fromRGB(12, 29, 43),
}

Theme.Stat = {
	Health = Color3.fromRGB(232, 79, 77),
	Hunger = Color3.fromRGB(245, 158, 48),
	Thirst = Color3.fromRGB(46, 148, 214),
	Stamina = Theme.Color.Green,
}

Theme.Rarity = {
	Common = Color3.fromRGB(110, 130, 135),
	Uncommon = Color3.fromRGB(59, 173, 107),
	Rare = Color3.fromRGB(41, 135, 199),
	Epic = Theme.Color.Orange,
	HighTier = Theme.Color.Coral,
	Legendary = Theme.Color.Yellow,
	Mythic = Theme.Color.Coral,
}

Theme.Radius = { Small = 10, Medium = 16, Large = 22, Pill = 999 }
Theme.Motion = {
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Panel = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Fade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

return Theme
