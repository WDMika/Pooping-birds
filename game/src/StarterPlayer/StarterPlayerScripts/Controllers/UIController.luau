-- Client-only interface. Game state is read from server-authored player attributes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UITheme"))
local UI = require(script.Parent:WaitForChild("UIComponents"))
local C = Theme.Color

local UIController = {}

local function setText(label, value)
	label.Text = tostring(value)
end

function UIController.new(config, actionRemote, feedbackRemote, player)
	local self = {
		Started = false,
		ModalOpen = false,
		CooldownEnds = 0,
		ActivePage = nil,
	}
	local gui = UI.New("ScreenGui", {
		Name = "PoopingBirdsUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}, player:WaitForChild("PlayerGui"))
	local root = UI.New("Frame", {
		Name = "Interface",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, gui)

	-- Header: brand and points at left, persistent navigation in the middle, bird and wanted status at right.
	local headerHolder, header = UI.Panel(root, "SkyHeader", UDim2.new(1, -48, 0, 82), UDim2.new(0.5, 0, 0, 12), C.Cream)
	headerHolder.AnchorPoint = Vector2.new(0.5, 0)
	headerHolder.Name = "Header"
	local headerLimit = UI.New("UISizeConstraint", { MaxSize = Vector2.new(1392, 140), MinSize = Vector2.new(300, 82) }, headerHolder)
	UI.Gradient(header, C.Cream, C.CreamDeep, 90)
	local logoTop = UI.Label(header, "POOPING", 20, C.Ink, true, { Name = "BrandTitle", Position = UDim2.fromOffset(18, 10), Size = UDim2.fromOffset(152, 27), ZIndex = 3 })
	local logoBottom = UI.Label(header, "BIRDS", 24, C.Orange, true, { Name = "BrandAccent", Position = UDim2.fromOffset(18, 37), Size = UDim2.fromOffset(106, 31), ZIndex = 3 })
	local points, pointsPlate = UI.Panel(header, "BirdPoints", UDim2.fromOffset(215, 49), UDim2.new(0.158, 0, 0.5, 0), C.Yellow, false)
	points.AnchorPoint = Vector2.new(0, 0.5)
	pointsPlate.Name = "PointsPlate"
	pointsPlate.BackgroundColor3 = C.Yellow
	pointsPlate:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, Theme.Radius.Medium)
	UI.Stroke(pointsPlate, C.Ink, 2)
	UI.New("Frame", { Name = "FeatherCoin", BackgroundColor3 = Color3.fromRGB(255, 226, 127), BorderSizePixel = 0, Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(35, 35), ZIndex = 3 }, pointsPlate)
	UI.Corner(pointsPlate.FeatherCoin, 18)
	UI.Label(pointsPlate.FeatherCoin, "*", 21, C.Ink, true, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })
	local pointsCaption = UI.Label(pointsPlate, "BIRD POINTS", 10, C.Ink, true, { Position = UDim2.fromOffset(54, 4), Size = UDim2.new(1, -62, 0, 14), ZIndex = 3 })
	local pointsValue = UI.Label(pointsPlate, "0", 21, C.Ink, true, { Name = "Value", Position = UDim2.fromOffset(54, 18), Size = UDim2.new(1, -62, 0, 26), ZIndex = 3 })

	local nav = UI.New("Frame", { Name = "Navigation", BackgroundTransparency = 1, Position = UDim2.new(0.34, 0, 0, 0), Size = UDim2.new(0.35, 0, 1, 0), ZIndex = 3 }, header)
	local navLayout = UI.New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, nav)
	local pages = { "SHOP", "BIRDS", "UPGRADES", "DAILY" }
	local pageColors = { SHOP = C.Blue, BIRDS = C.Green, UPGRADES = C.Ink, DAILY = C.Orange }
	local navButtons = {}
	for index, page in ipairs(pages) do
		local width = page == "UPGRADES" and 126 or 103
		local button = UI.Button(nav, "Nav" .. page, page, UDim2.fromOffset(width, 50), pageColors[page], C.Cream)
		button.LayoutOrder = index
		button.TextSize = 14
		navButtons[page] = button
	end

	local birdBadge = UI.New("Frame", { Name = "BirdBadge", BackgroundColor3 = C.CreamDeep, BorderSizePixel = 0, Position = UDim2.new(0.724, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(183, 50), ZIndex = 3 }, header)
	UI.Corner(birdBadge, Theme.Radius.Medium); UI.Stroke(birdBadge, C.Ink, 2)
	local birdGlyph = UI.New("Frame", { BackgroundColor3 = Color3.fromRGB(115, 163, 141), BorderSizePixel = 0, Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(31, 31), ZIndex = 4 }, birdBadge)
	UI.Corner(birdGlyph, 18)
	local birdLetter = UI.Label(birdGlyph, "P", 17, C.Cream, true, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5 })
	UI.Label(birdBadge, "FLYING AS", 9, C.Ink, true, { Position = UDim2.fromOffset(49, 5), Size = UDim2.fromOffset(124, 13), ZIndex = 4 })
	local birdName = UI.Label(birdBadge, "PIGEON  |  EQUIPPED", 12, C.Ink, true, { Name = "Equipped", Position = UDim2.fromOffset(49, 19), Size = UDim2.fromOffset(127, 24), ZIndex = 4 })

	local wantedBox = UI.New("Frame", { Name = "WantedStars", BackgroundColor3 = Color3.fromRGB(252, 222, 199), BorderSizePixel = 0, Position = UDim2.new(1, -187, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(164, 59), ZIndex = 3 }, header)
	UI.Corner(wantedBox, Theme.Radius.Medium); UI.Stroke(wantedBox, Color3.fromRGB(163, 54, 48), 2)
	UI.Label(wantedBox, "WANTED", 10, Color3.fromRGB(140, 41, 41), true, { Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -20, 0, 15), ZIndex = 4 })
	local wantedValue = UI.Label(wantedBox, "☆ ☆ ☆ ☆ ☆", 19, C.Coral, true, { Name = "Stars", Position = UDim2.fromOffset(6, 20), Size = UDim2.new(1, -12, 0, 31), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })

	-- Compact four-meter stack.
	local vitalsHolder, vitals = UI.Panel(root, "FlightCheck", UDim2.fromOffset(278, 220), UDim2.new(0, 24, 1, -257), C.Cream)
	vitalsHolder.Name = "Vitals"
	local vitalsTitle = UI.Label(vitals, "FLIGHT CHECK", 14, C.Ink, true, { Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -36, 0, 25), ZIndex = 3 })
	local barWidgets = {}
	for index, stat in ipairs({
		{ "Health", "HEALTH", Theme.Stat.Health },
		{ "Hunger", "HUNGER", Theme.Stat.Hunger },
		{ "Thirst", "THIRST", Theme.Stat.Thirst },
		{ "Stamina", "STAMINA", Theme.Stat.Stamina },
	}) do
		local y = 48 + (index - 1) * 39
		local title = UI.Label(vitals, stat[2], 10, C.Ink, true, { Name = stat[1] .. "Label", Position = UDim2.fromOffset(18, y), Size = UDim2.fromOffset(120, 14), ZIndex = 3 })
		local value = UI.Label(vitals, "100%", 10, C.Ink, true, { Position = UDim2.new(1, -58, 0, y), Size = UDim2.fromOffset(40, 14), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3 })
		local track = UI.New("Frame", { Name = stat[1] .. "Track", BackgroundColor3 = C.Track, BorderSizePixel = 0, Position = UDim2.fromOffset(18, y + 18), Size = UDim2.new(1, -36, 0, 12), ZIndex = 3 }, vitals)
		UI.Corner(track, 6)
		local fill = UI.New("Frame", { Name = stat[1] .. "Fill", BackgroundColor3 = stat[3], BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, track)
		UI.Corner(fill, 6)
		barWidgets[stat[1]] = { Fill = fill, Value = value, Color = stat[3] }
	end

	-- Primary action and feedback remain above, but away from, the flight center.
	local dropHolder, dropButton = UI.Panel(root, "DropAction", UDim2.fromOffset(308, 76), UDim2.new(0.5, 0, 1, -39), C.Yellow)
	dropHolder.AnchorPoint = Vector2.new(0.5, 1)
	dropButton.Name = "DropPlate"
	dropButton.BackgroundColor3 = C.Yellow
	UI.Gradient(dropButton, Color3.fromRGB(255, 216, 83), C.Yellow, 90)
	local keycap = UI.New("Frame", { Name = "Keycap", BackgroundColor3 = C.Cream, BorderSizePixel = 0, Position = UDim2.fromOffset(15, 15), Size = UDim2.fromOffset(52, 46), ZIndex = 3 }, dropButton)
	UI.Corner(keycap, 13); UI.Stroke(keycap, C.Ink, 2)
	UI.Label(keycap, "Q", 24, C.Ink, true, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })
	local dropTitle = UI.Label(dropButton, "DROP A LOAD!", 19, C.Ink, true, { Position = UDim2.fromOffset(78, 10), Size = UDim2.new(1, -88, 0, 29), ZIndex = 3 })
	local dropStatus = UI.Label(dropButton, "READY  |  MULTIPLIER x1", 10, C.Ink, true, { Position = UDim2.fromOffset(78, 39), Size = UDim2.new(1, -88, 0, 20), ZIndex = 3 })
	local poopButton = UI.New("TextButton", { Name = "PoopInput", BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 5, AutoButtonColor = false }, dropButton)
	poopButton.Activated:Connect(function()
		if self.Started and not self.ModalOpen and os.clock() >= self.CooldownEnds then
			self.OnPoop()
		end
	end)
	local returnButton = UI.Button(root,"ReturnNest","RETURN TO NEST [H]",UDim2.fromOffset(182,42),C.GreenDark,C.Cream)
	returnButton.AnchorPoint=Vector2.new(1,1);returnButton.Position=UDim2.new(1,-24,1,-88);returnButton.TextSize=11
	returnButton.Activated:Connect(function() actionRemote:FireServer("ReturnToHub") end)
	local controls = UI.Label(root, "WASD FLY     SPACE CLIMB     SHIFT BOOST", 10, C.Ink, true, {
		Name = "ControlsHint", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -26),		Size = UDim2.fromOffset(352, 44), BackgroundColor3 = C.Cream, BackgroundTransparency = 0,
		BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3,
	})
	UI.Corner(controls, Theme.Radius.Medium); UI.Stroke(controls, C.Ink, 2)

	local scoreHolder, scoreCard = UI.Panel(root, "ScoreFeedback", UDim2.fromOffset(378, 116), UDim2.new(0.5, 0, 0.65, 0), C.Cream)
	scoreHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	scoreHolder.Visible = false
	scoreHolder.ZIndex = 8
	scoreCard.ZIndex = 9
	UI.Gradient(scoreCard, C.Cream, C.CreamDeep, 90)
	local hitTag = UI.New("Frame", { BackgroundColor3 = C.Coral, BorderSizePixel = 0, Position = UDim2.new(0.5, -74, 0, 12), Size = UDim2.fromOffset(148, 25), ZIndex = 10 }, scoreCard)
	UI.Corner(hitTag, 12)
	local hitTitle = UI.Label(hitTag, "HEADSHOT!", 13, C.Cream, true, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 11 })
	local hitPoints = UI.Label(scoreCard, "+0", 40, C.Ink, true, { Name = "Reward", Position = UDim2.new(0, 32, 0, 38), Size = UDim2.fromOffset(172, 60), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 10 })
	local hitMultiplier = UI.Label(scoreCard, "x1  |  CITY BONUS", 13, C.GreenDark, true, { Name = "Multiplier", Position = UDim2.new(0.54, 0, 0, 50), Size = UDim2.new(0.44, -15, 0, 34), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 10 })
	local hitStroke = scoreCard:FindFirstChildOfClass("UIStroke")
	local hitToken = 0
	local lastMultiplier

	local toast = UI.Label(root, "", 18, C.Cream, true, { Name = "Toast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 116), Size = UDim2.fromOffset(560, 48), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, ZIndex = 15 })
	local toastPlate = UI.New("Frame", { Name = "ToastPlate", BackgroundColor3 = C.Ink, BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 1), ZIndex = 14 }, toast)
	toastPlate.Parent = toast
	UI.Corner(toastPlate, Theme.Radius.Medium)
	local toastToken = 0
	local function showToast(message, color)
		toastToken += 1
		local token = toastToken
		toast.Text = tostring(message)
		toast.TextColor3 = color or C.Cream
		toast.TextTransparency = 1
		toastPlate.BackgroundTransparency = 0.08
		TweenService:Create(toast, Theme.Motion.Fade, { TextTransparency = 0 }):Play()
		task.delay(2, function()
			if token == toastToken then
				TweenService:Create(toast, Theme.Motion.Fade, { TextTransparency = 1 }):Play()
				TweenService:Create(toastPlate, Theme.Motion.Fade, { BackgroundTransparency = 1 }):Play()
			end
		end)
	end

	-- Menu panels use a shared content shell and explicit backend state messages.
	local modalLayer = UI.New("Frame", { Name = "ModalLayer", BackgroundColor3 = C.Overlay, BackgroundTransparency = 0.32, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 20 }, root)
	local modal, modalPlate = UI.Panel(modalLayer, "NavigationPanel", UDim2.new(1, -40, 1, -160), UDim2.fromScale(0.5, 0.5), C.Cream)
	modal.Name = "PanelHolder"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modalPlate.Name = "Panel"
	modalPlate.ClipsDescendants = true
	UI.New("UISizeConstraint", { MinSize = Vector2.new(280, 360), MaxSize = Vector2.new(840, 580) }, modal)
	UI.Gradient(modalPlate, C.Cream, C.CreamDeep, 90)
	local modalTitle = UI.Label(modalPlate, "BIRD SHOP", 26, C.Ink, true, { Name = "Title", Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -104, 0, 42), ZIndex = 24 })
	local modalSubtitle = UI.Label(modalPlate, "Find your next rooftop legend.", 12, C.Muted, false, { Name = "Subtitle", Position = UDim2.fromOffset(25, 53), Size = UDim2.new(1, -50, 0, 22), ZIndex = 24 })
	local pointsPill = UI.Label(modalPlate, "0 BIRD POINTS", 12, C.Ink, true, { Name = "PanelCurrency", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -78, 0, 24), Size = UDim2.fromOffset(150, 24), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 24 })
	local closeButton = UI.Button(modalPlate, "Close", "X", UDim2.fromOffset(42, 42), C.Coral, C.Cream)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -14, 0, 13)
	closeButton.TextSize = 18
	local tabBar = UI.New("Frame", { Name = "Tabs", BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 82), Size = UDim2.new(1, -40, 0, 39), ZIndex = 24 }, modalPlate)
	local tabLayout = UI.New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)
	local tabButtons = {}
	for index, page in ipairs(pages) do
		local b = UI.Button(tabBar, "Tab" .. page, page, UDim2.new(0.25, -6, 1, 0), pageColors[page], C.Cream)
		b.LayoutOrder = index
		b.TextSize = 12
		tabButtons[page] = b
	end
	local list = UI.New("ScrollingFrame", {
		Name = "PageContent",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 133),
		Size = UDim2.new(1, -40, 1, -153),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.Blue,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 24,
	}, modalPlate)
	local listGrid = UI.New("UIGridLayout", { Name = "CardGrid", CellSize = UDim2.new(0.5, -8, 0, 124), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	UI.New("UIPadding", { PaddingBottom = UDim.new(0, 12), PaddingRight = UDim.new(0, 5) }, list)

	local function clearContent()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
	end

	local function makeCard(name, eyebrow, desc, order, accent)
		local card = UI.New("Frame", { Name = name, BackgroundColor3 = C.Cream, BorderSizePixel = 0, LayoutOrder = order, ZIndex = 25 }, list)
		UI.Corner(card, Theme.Radius.Medium); UI.Stroke(card, C.Ink, 2)
		local bar = UI.New("Frame", { Name = "Accent", BackgroundColor3 = accent or C.Blue, BorderSizePixel = 0, Size = UDim2.new(0, 7, 1, 0), ZIndex = 26 }, card)
		UI.Corner(bar, 5)
		local title = UI.Label(card, name, 16, C.Ink, true, { Position = UDim2.fromOffset(17, 8), Size = UDim2.new(1, -34, 0, 23), ZIndex = 27 })
		local meta = UI.Label(card, eyebrow, 10, accent or C.Muted, true, { Position = UDim2.fromOffset(17, 33), Size = UDim2.new(1, -34, 0, 16), ZIndex = 27 })
		local detail = UI.Label(card, desc, 11, C.Muted, false, { Position = UDim2.fromOffset(17, 51), Size = UDim2.new(1, -34, 0, 33), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 27 })
		return card, title, meta, detail
	end

	local function birdCard(name, index, page)
		local bird = config.Birds[name]
		if not bird then return end
		local owned = player:GetAttribute("Owned_" .. name) == true or name == "Pigeon"
		local equipped = player:GetAttribute("EquippedBird") == name
		local rarity = Theme.Rarity[bird.Rarity] or C.Muted
		local status = equipped and "EQUIPPED" or (owned and "IN YOUR FLOCK" or (bird.PremiumPlaceholder and "COMING SOON" or ("UNLOCK  |  " .. tostring(bird.Cost) .. " BP")))
		local statLine = string.format("Power %d   Speed %.2f   Health %d", bird.BodyPower, bird.Speed, bird.Health)
		local card = UI.New("Frame", { Name = name .. "Card", BackgroundColor3 = C.Cream, BorderSizePixel = 0, LayoutOrder = index, ZIndex = 25 }, list)
		UI.Corner(card, Theme.Radius.Medium); UI.Stroke(card, C.Ink, 2)
		local swatch = UI.New("Frame", { Name = "BirdSwatch", BackgroundColor3 = bird.Color, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 18), Size = UDim2.fromOffset(62, 62), ZIndex = 26 }, card)
		UI.Corner(swatch, 31); UI.Stroke(swatch, C.Ink, 2)
		UI.Label(swatch, string.sub(string.upper(bird.DisplayName), 1, 1), 24, C.Cream, true, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 27 })
		UI.Label(card, string.upper(bird.DisplayName), 16, C.Ink, true, { Position = UDim2.fromOffset(84, 10), Size = UDim2.new(1, -100, 0, 22), ZIndex = 27 })
		local rarityChip = UI.New("Frame", { Name = "Rarity", BackgroundColor3 = rarity, BorderSizePixel = 0, Position = UDim2.fromOffset(84, 36), Size = UDim2.fromOffset(78, 19), ZIndex = 27 }, card)
		UI.Corner(rarityChip, 9)
		UI.Label(rarityChip, string.upper(bird.Rarity), 9, C.White, true, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 28 })
		UI.Label(card, statLine, 10, C.Muted, false, { Position = UDim2.fromOffset(84, 59), Size = UDim2.new(1, -97, 0, 18), ZIndex = 27 })
		local button = UI.Button(card, name .. "Action", status, UDim2.new(1, -24, 0, 29), equipped and C.Green or (owned and C.Blue or C.Yellow), equipped and C.White or C.Ink)
		button.Position = UDim2.new(0, 12, 1, -38)
		button.TextSize = 11
		if bird.PremiumPlaceholder then
			UI.DisableButton(button, "COMING SOON")
		elseif page == "BIRDS" and not owned then
			UI.DisableButton(button, "LOCKED  |  SEE SHOP")
		elseif equipped then
			UI.DisableButton(button, "EQUIPPED")
		else
			button.Activated:Connect(function()
				if owned then
					actionRemote:FireServer("EquipBird", name)
				else
					actionRemote:FireServer("BuyBird", name)
				end
			end)
		end
	end

	local function drawBirds(page)
		clearContent()
		for order, name in ipairs(config.BirdOrder) do
			if config.Birds[name] then birdCard(name, order, page) end
		end
	end

	local function upgradeValues(key, level)
		local birdName = player:GetAttribute("EquippedBird") or "Pigeon"
		local bird = config.Birds[birdName] or config.Birds.Pigeon
		if key == "FlightSpeed" then return string.format("x%.2f speed", 1 + level * config.Upgrades.FlightSpeed.Step) end
		if key == "Stamina" then
			local spec = config.Upgrades.Stamina
			if level == 0 then return "base drain / regen" end
			return string.format("%d%% less drain / %d%% more regen", math.floor(level * spec.DrainStep * 100), math.floor(level * spec.RegenStep * 100))
		end
		if key == "Health" then return string.format("%d max HP", bird.Health + level * config.Upgrades.Health.Step) end
		if key == "PoopCooldown" then
			local spec = config.Upgrades.PoopCooldown
			return string.format("%.2fs cooldown", math.max(spec.Minimum, bird.Cooldown - level * spec.Step))
		end
		if key == "Multiplier" then return string.format("+%.2fx per hit", level * config.Upgrades.Multiplier.Step) end
		return "—"
	end

	local function drawUpgrades()
		clearContent()
		for order, key in ipairs({ "FlightSpeed", "Stamina", "Health", "PoopCooldown", "Multiplier" }) do
			local spec = config.Upgrades[key]
			local level = math.clamp(tonumber(player:GetAttribute("Upgrade_" .. key)) or 0, 0, spec.MaxLevel)
			local nextLevel = math.min(level + 1, spec.MaxLevel)
			local maxed = level >= spec.MaxLevel
			local price = not maxed and spec.Costs[nextLevel] or nil
			local meta = string.format("LEVEL %d / %d", level, spec.MaxLevel)
			local detail = "NOW  " .. upgradeValues(key, level) .. "   |   NEXT  " .. upgradeValues(key, nextLevel)
			if maxed then detail = "MAX LEVEL  |  " .. upgradeValues(key, level) else detail ..= "\nPRICE  " .. tostring(price) .. " BIRD POINTS" end
			local card = makeCard(spec.DisplayName, meta, detail, order, key == "Multiplier" and C.Orange or C.Blue)
			local button = UI.Button(card, key .. "Upgrade", maxed and "MAX LEVEL" or ("UPGRADE  |  " .. tostring(price) .. " BP"), UDim2.new(1, -24, 0, 28), maxed and C.Muted or C.Yellow, maxed and C.Cream or C.Ink)
			button.Position = UDim2.new(0, 12, 1, -36); button.TextSize = 10
			if maxed then UI.DisableButton(button, "MAX LEVEL") else button.Activated:Connect(function() actionRemote:FireServer("Upgrade", key) end) end
		end
	end

	local function drawDailyRewards()
		clearContent()
		local ready = player:GetAttribute("DailyReady") == true
		local claimedDay = tonumber(player:GetAttribute("DailyClaimedDay")) or 0
		local nextDay = math.clamp(tonumber(player:GetAttribute("DailyNextDay")) or 1, 1, 7)
		local streak = tonumber(player:GetAttribute("DailyStreak")) or 0
		local intro = UI.New("Frame", { Name = "DailyStatus", BackgroundColor3 = C.Cream, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 74), ZIndex = 25 }, list)
		UI.Corner(intro, Theme.Radius.Medium); UI.Stroke(intro, C.Ink, 2)
		UI.Label(intro, ready and ("DAY " .. nextDay .. " IS READY") or ("DAY " .. claimedDay .. " CLAIMED  •  STREAK " .. streak), 17, C.Ink, true, { Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -32, 0, 25), ZIndex = 26 })
		UI.Label(intro, ready and "Claim once today. Miss a day and your streak returns to Day 1. Resets at 00:00 UTC." or "Come back after the daily reset to continue your streak.", 11, C.Muted, false, { Position = UDim2.fromOffset(16, 36), Size = UDim2.new(1, -32, 0, 30), TextWrapped = true, ZIndex = 26 })
		for day, reward in ipairs(config.DailyRewards) do
			local isClaimed = not ready and day == claimedDay
			local isAvailable = ready and day == nextDay
			local isFinal = day == 7
			local card = UI.New("Frame", { Name = "Day" .. day, BackgroundColor3 = isFinal and Color3.fromRGB(255, 238, 183) or C.Cream, BorderSizePixel = 0, LayoutOrder = day, ZIndex = 25 }, list)
			UI.Corner(card, Theme.Radius.Medium); UI.Stroke(card, isFinal and C.Orange or C.Ink, isFinal and 3 or 2)
			UI.Label(card, isFinal and "DAY 7  •  BIG FINALE" or ("DAY " .. day), 14, C.Ink, true, { Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 23), ZIndex = 26 })
			UI.Label(card, tostring(reward) .. " BIRD POINTS", 12, C.Muted, true, { Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 19), ZIndex = 26 })
			local state = isClaimed and "CLAIMED" or (isAvailable and "CLAIM REWARD" or "LOCKED")
			local button = UI.Button(card, "Day" .. day .. "Action", state, UDim2.new(1, -24, 0, 29), isAvailable and C.Green or (isClaimed and C.Blue or C.Muted), C.Cream)
			button.Position = UDim2.new(0, 12, 1, -39); button.TextSize = 10
			if isAvailable then button.Activated:Connect(function() actionRemote:FireServer("ClaimDaily") end) else UI.DisableButton(button, state) end
		end
	end

	local function redraw(page)
		self.ActivePage = page
		modalTitle.Text = page == "SHOP" and "BIRD SHOP" or (page == "BIRDS" and "MY FLOCK" or (page == "DAILY" and "DAILY REWARDS" or "BIRD UPGRADES"))
		modalSubtitle.Text = page == "SHOP" and "Unlock a new flyer with Bird Points." or (page == "BIRDS" and "Your collection and its real flight stats." or (page == "DAILY" and "Show up daily to earn a growing point reward." or "Spend Bird Points to improve your flying."))
		local ownedOnly = page == "BIRDS"
		pointsPill.Text = tostring(player:GetAttribute("Points") or 0) .. " BIRD POINTS"
		for tab, button in pairs(tabButtons) do
			button.BackgroundColor3 = page == tab and C.Yellow or pageColors[tab]
			button.TextColor3 = page == tab and C.Ink or C.Cream
		end
		if page == "SHOP" or page == "BIRDS" then
			modalSubtitle.Text = ownedOnly and "Owned birds can be equipped here. Visit the shop to unlock more." or "Real bird stats and Bird Point prices from the game."
			drawBirds(page)
		elseif page == "UPGRADES" then
			drawUpgrades()
		else
			drawDailyRewards()
		end
		modalLayer.Visible = true
		self.ModalOpen = true
		modal.Size = UDim2.new(1, -40, 1, -160)
		modalPlate.Size = UDim2.fromScale(1, 1)
		modalPlate.Position = UDim2.fromScale(0, 0)
		modal.Position = UDim2.fromScale(0.5, 0.5)
		modal.AnchorPoint = Vector2.new(0.5, 0.5)
		modalPlate.BackgroundTransparency = 0
		local target = modal.Size
		modal.Size = UDim2.new(target.X.Scale, target.X.Offset - 14, target.Y.Scale, target.Y.Offset - 14)
		TweenService:Create(modal, Theme.Motion.Panel, { Size = target }):Play()
	end

	local intro
	local function closeModal()
		modalLayer.Visible = false
		self.ModalOpen = false
		if not self.Started and intro then intro.Visible = true end
	end
	for page, button in pairs(navButtons) do button.Activated:Connect(function() redraw(page) end) end
	for page, button in pairs(tabButtons) do button.Activated:Connect(function() redraw(page) end) end
	closeButton.Activated:Connect(closeModal)

	-- Intro screen
	intro = UI.New("Frame", { Name = "MainMenu", BackgroundColor3 = C.Overlay, BackgroundTransparency = 0.42, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 40 }, root)
	local introCard, introPlate = UI.Panel(intro, "Welcome", UDim2.fromOffset(520, 378), UDim2.fromScale(0.5, 0.5), C.Cream)
	introCard.AnchorPoint = Vector2.new(0.5, 0.5); introCard.ZIndex = 41; introPlate.ZIndex = 42
	UI.Gradient(introPlate, C.Cream, C.CreamDeep, 90)
	UI.Label(introPlate, "POOPING", 46, C.Ink, true, { Position = UDim2.new(0, 25, 0, 33), Size = UDim2.new(1, -50, 0, 58), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43 })
	UI.Label(introPlate, "BIRDS", 51, C.Orange, true, { Position = UDim2.new(0, 25, 0, 83), Size = UDim2.new(1, -50, 0, 61), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43 })
	UI.Label(introPlate, "TAKE FLIGHT. MAKE A MESS. RULE THE ROOFTOPS.", 13, C.Muted, true, { Position = UDim2.new(0, 24, 0, 151), Size = UDim2.new(1, -48, 0, 26), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43 })
	local playButton = UI.Button(introPlate, "Play", "LET'S FLY!", UDim2.new(1, -70, 0, 58), C.Green, C.Cream)
	playButton.Position = UDim2.new(0, 35, 0, 198); playButton.TextSize = 22; playButton.ZIndex = 43
	local menuBirds = UI.Button(introPlate, "OpenBirds", "BIRD SHOP", UDim2.new(0.5, -42, 0, 48), C.Blue, C.Cream)
	menuBirds.Position = UDim2.new(0, 35, 0, 270); menuBirds.ZIndex = 43
	local menuSettings = UI.Button(introPlate, "OpenSettings", "CONTROLS", UDim2.new(0.5, -42, 0, 48), C.Ink, C.Cream)
	menuSettings.Position = UDim2.new(0.5, 7, 0, 270); menuSettings.ZIndex = 43
	local controlsText = UI.Label(introPlate, "FLY  WASD / STICK     CLIMB  SPACE     BOOST  SHIFT\nDROP  Q / TAP     FOOD  FLY CLOSE + E", 11, C.Muted, true, { Name = "Controls", Position = UDim2.new(0, 24, 1, -51), Size = UDim2.new(1, -48, 0, 41), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true, ZIndex = 43 })
	local settingsLabel = UI.Label(introPlate, "Flight: WASD + mouse aim   |   Space: climb   |   Ctrl: dive   |   Shift: boost\nDrop: Q / HUD button   |   Bird shop: B   |   Food: fly close and press E", 12, C.Muted, false, { Name = "SettingsInfo", Position = UDim2.new(0, 24, 1, -105), Size = UDim2.new(1, -48, 0, 51), TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, Visible = false, ZIndex = 43 })
	playButton.Activated:Connect(function()
		self.Started = true
		intro.Visible = false
	end)
	menuBirds.Activated:Connect(function() intro.Visible = false; redraw("SHOP") end)
	menuSettings.Activated:Connect(function()
		settingsLabel.Visible = not settingsLabel.Visible
		controlsText.Visible = not settingsLabel.Visible
	end)

	function self.OnPoop() end
	function self:SetCooldown(seconds)
		self.CooldownEnds = os.clock() + (tonumber(seconds) or 1.5)
	end
	function self:CanPoop()
		return self.Started and not self.ModalOpen and os.clock() >= self.CooldownEnds
	end
	function self:IsBlockingInput()
		return not self.Started or self.ModalOpen or player:GetAttribute("Captured") == true
	end
	function self:ShowToast(message, color)
		showToast(message, color)
	end
	local function animateHit(payload)
		hitToken += 1
		local token = hitToken
		lastMultiplier = payload.Multiplier
		hitTitle.Text = payload.Headshot and "HEADSHOT!" or "CLEAN HIT!"
		hitTag.BackgroundColor3 = payload.Headshot and C.Coral or C.Green
		hitPoints.Text = "+" .. tostring(payload.Points or 0)
		hitMultiplier.Text = string.format("x%s  |  %s STUDS", tostring(payload.Multiplier or 1), tostring(payload.Height or 0))
		scoreHolder.Visible = true
		scoreHolder.Position = UDim2.new(0.5, 0, 0.64, 18)
		scoreHolder.Size = UDim2.fromOffset(332, 100)
		TweenService:Create(scoreHolder, Theme.Motion.Panel, { Position = UDim2.new(0.5, 0, 0.64, 0), Size = UDim2.fromOffset(378, 116) }):Play()
		if hitStroke then hitStroke.Color = payload.Headshot and C.Orange or C.Green end
		task.delay(1.9, function()
			if token == hitToken then
				local tween = TweenService:Create(scoreHolder, Theme.Motion.Fade, { Position = scoreHolder.Position - UDim2.fromOffset(0, 16) })
				tween:Play()
				task.delay(0.18, function() if token == hitToken then scoreHolder.Visible = false end end)
			end
		end)
	end
	feedbackRemote.OnClientEvent:Connect(function(kind, payload)
		if kind == "Toast" then
			showToast(tostring(payload), C.Yellow)
		elseif kind == "Defeat" then
			showToast(tostring(payload), C.Coral)
		elseif kind == "OpenPage" and (payload=="SHOP" or payload=="BIRDS" or payload=="UPGRADES" or payload=="DAILY") then
			intro.Visible=false;redraw(payload)
		elseif kind == "Cooldown" then
			self:SetCooldown(payload)
		elseif kind == "Hit" and type(payload) == "table" then
			animateHit(payload)
		end
	end)

	local defeatLayer = UI.New("Frame", { Name="DefeatTransition", BackgroundColor3=C.Overlay, BackgroundTransparency=0.2, BorderSizePixel=0, Size=UDim2.fromScale(1,1), Visible=false, ZIndex=60 }, root)
	local defeatTitle = UI.Label(defeatLayer,"BACK TO THE ROOST",28,C.Cream,true,{Position=UDim2.fromScale(0.1,0.4),Size=UDim2.fromScale(0.8,0.12),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=61})
	UI.Label(defeatLayer,"Your Bird Points and unlocked birds are safe.",16,C.Yellow,false,{Position=UDim2.fromScale(0.1,0.53),Size=UDim2.fromScale(0.8,0.1),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=true,ZIndex=61})
	local function refreshDefeat()
		local captured=player:GetAttribute("Captured")==true
		defeatLayer.Visible=captured or (tonumber(player:GetAttribute("Health")) or 100)<=0
		defeatTitle.Text=captured and "CAUGHT BY BIRD CATCHERS!" or "BACK TO THE ROOST"
	end
	player:GetAttributeChangedSignal("Captured"):Connect(refreshDefeat)
	player:GetAttributeChangedSignal("Health"):Connect(refreshDefeat)
	refreshDefeat()

	local function refreshBirdDetails()
		local equipped = player:GetAttribute("EquippedBird") or "Pigeon"
		local bird = config.Birds[equipped] or config.Birds.Pigeon
		birdLetter.Text = string.sub(string.upper(bird.DisplayName), 1, 1)
		birdName.Text = string.upper(bird.DisplayName) .. "  |  EQUIPPED"
		birdGlyph.BackgroundColor3 = bird.Color
		pointsValue.Text = tostring(player:GetAttribute("Points") or 0)
		pointsPill.Text = tostring(player:GetAttribute("Points") or 0) .. " BIRD POINTS"
		local wanted = math.clamp(tonumber(player:GetAttribute("Wanted")) or 0, 0, 5)
		wantedValue.Text = string.rep("★ ", wanted) .. string.rep("☆ ", 5 - wanted)
		wantedValue.Text = string.gsub(wantedValue.Text, "%s+$", "")
		if self.ActivePage == "SHOP" or self.ActivePage == "BIRDS" then
			drawBirds(self.ActivePage)
		elseif self.ActivePage == "UPGRADES" then
			redraw("UPGRADES")
		elseif self.ActivePage == "DAILY" then
			redraw("DAILY")
		end
	end
	for _, attribute in ipairs({ "Points", "EquippedBird", "Wanted", "Owned_Pigeon", "Owned_Raven", "Owned_Seagull", "BodyPower", "Owned_Owl", "Owned_Falcon", "Owned_Eagle", "Owned_Phoenix", "Upgrade_FlightSpeed", "Upgrade_Stamina", "Upgrade_Health", "Upgrade_PoopCooldown", "Upgrade_Multiplier", "DailyReady", "DailyClaimedDay", "DailyNextDay", "DailyStreak" }) do
		player:GetAttributeChangedSignal(attribute):Connect(refreshBirdDetails)
	end
	refreshBirdDetails()

	local viewport = root.AbsoluteSize
	local function layoutFor(size)
		local compact = size.X < 720
		returnButton.AnchorPoint=compact and Vector2.new(1,0) or Vector2.new(1,1)
		returnButton.Position=compact and UDim2.new(1,-12,0,138) or UDim2.new(1,-24,1,-88)
		headerHolder.Size = compact and UDim2.new(1, -20, 0, 126) or UDim2.new(1, -48, 0, 82)
		if compact then
		headerHolder.Position = UDim2.new(0.5, 0, 0, 5)
			logoTop.TextSize = 13; logoTop.Position = UDim2.fromOffset(10, 8); logoTop.Size = UDim2.fromOffset(88, 19)
			logoBottom.TextSize = 17; logoBottom.Position = UDim2.fromOffset(10, 28); logoBottom.Size = UDim2.fromOffset(73, 24)
			points.Position = UDim2.new(0, 88, 0, 8); points.Size = UDim2.fromOffset(112, 43)
			pointsPlate.FeatherCoin.Size = UDim2.fromOffset(27, 27); pointsPlate.FeatherCoin.Position = UDim2.fromOffset(5, 8)
		pointsCaption.TextSize = 8
			pointsPlate:FindFirstChild("Value").Position = UDim2.fromOffset(38, 16); pointsPlate.Value.TextSize = 17
			pointsPlate.Value.Size = UDim2.new(1, -43, 0, 23)
			nav.Position = UDim2.new(0, 8, 0, 62); nav.Size = UDim2.new(1, -16, 0, 49)
			navLayout.Padding = UDim.new(0, 5)
			for page, button in pairs(navButtons) do
				local fractions = { SHOP = 0.2, BIRDS = 0.2, UPGRADES = 0.31, DAILY = 0.22 }
				button.Size = UDim2.new(fractions[page], -4, 0, 43); button.TextSize = 11
			end
			birdBadge.Visible = false
			wantedBox.Position = UDim2.new(1, -105, 0, 8); wantedBox.Size = UDim2.fromOffset(98, 43)
			wantedBox:FindFirstChild("Label").TextSize = 8; wantedBox.Label.Position = UDim2.fromOffset(6, 2); wantedBox.Label.Size = UDim2.new(1, -12, 0, 12)
			wantedValue.Position = UDim2.fromOffset(2, 14); wantedValue.Size = UDim2.new(1, -4, 0, 24); wantedValue.TextSize = 11
			vitalsHolder.Size = UDim2.new(1, -24, 0, 164); vitalsHolder.Position = UDim2.new(0, 12, 1, -190)
			vitalsTitle.Position = UDim2.fromOffset(12, 7); vitalsTitle.Size = UDim2.new(1, -24, 0, 20); vitalsTitle.TextSize = 11
			for index, stat in ipairs({ "Health", "Hunger", "Thirst", "Stamina" }) do
				local row = barWidgets[stat]
				local y = 30 + (index - 1) * 31
				row.Value.Position = UDim2.new(1, -52, 0, y); row.Value.Size = UDim2.fromOffset(38, 13); row.Value.TextSize = 9
				row.Fill.Parent.Position = UDim2.fromOffset(12, y + 14); row.Fill.Parent.Size = UDim2.new(1, -24, 0, 9)
				local statTitle = row.Value.Parent:FindFirstChild(stat .. "Label")
				if statTitle then statTitle.Position = UDim2.fromOffset(12, y); statTitle.Size = UDim2.fromOffset(110, 13); statTitle.TextSize = 9 end
			end
			dropHolder.Size = UDim2.new(0, math.max(260, math.min(size.X - 24, 308)), 0, 62)
			dropHolder.Position = UDim2.new(0.5, 0, 1, -198)
			keycap.Size = UDim2.fromOffset(42, 38); keycap.Position = UDim2.fromOffset(10, 12)
			dropTitle.Position = UDim2.fromOffset(62, 8); dropTitle.Size = UDim2.new(1, -70, 0, 23); dropTitle.TextSize = 15
			dropStatus.Position = UDim2.fromOffset(62, 31); dropStatus.Size = UDim2.new(1, -70, 0, 18); dropStatus.TextSize = 9
			controls.Visible = false
			modal.Position = UDim2.fromScale(0.5, 0.5)
			modal.Size = UDim2.new(1, -24, 1, -154)
			modalPlate.Size = UDim2.fromScale(1, 1)
			modalTitle.Position = UDim2.fromOffset(16, 10); modalTitle.TextSize = 18
			modalSubtitle.Position = UDim2.fromOffset(17, 43); modalSubtitle.TextSize = 10
			closeButton.Size = UDim2.fromOffset(34, 34); closeButton.Position = UDim2.new(1, -8, 0, 8); closeButton.TextSize = 14
			pointsPill.Visible = false
			tabBar.Position = UDim2.fromOffset(12, 72); tabBar.Size = UDim2.new(1, -24, 0, 35); tabLayout.Padding = UDim.new(0, 4)
			for _, b in pairs(tabButtons) do b.TextSize = 9 end
			list.Position = UDim2.fromOffset(12, 118); list.Size = UDim2.new(1, -24, 1, -130)
			listGrid.CellSize = UDim2.new(1, -7, 0, 124); listGrid.CellPadding = UDim2.fromOffset(5, 7)
			introCard.Size = UDim2.new(1, -24, 0, 350)
			introCard.Position = UDim2.fromScale(0.5, 0.5)
			playButton.Position = UDim2.new(0, 20, 0, 187); playButton.Size = UDim2.new(1, -40, 0, 54); playButton.TextSize = 19
			menuBirds.Position = UDim2.new(0, 20, 0, 253); menuBirds.Size = UDim2.new(0.5, -25, 0, 44); menuSettings.Position = UDim2.new(0.5, 5, 0, 253); menuSettings.Size = UDim2.new(0.5, -25, 0, 44)
			settingsLabel.TextSize = 9; controlsText.TextSize = 9
			scoreHolder.Size = UDim2.fromOffset(math.min(size.X - 32, 350), 104)
		elseif size.X < 1320 then
			headerHolder.Position = UDim2.new(0.5, 0, 0, 8)
			logoTop.TextSize = 15; logoTop.Position = UDim2.fromOffset(10, 13); logoTop.Size = UDim2.fromOffset(92, 21)
			logoBottom.TextSize = 18; logoBottom.Position = UDim2.fromOffset(10, 34); logoBottom.Size = UDim2.fromOffset(82, 26)
			points.Size = UDim2.fromOffset(140, 46); points.Position = UDim2.new(0.16, 0, 0.5, 0)
			nav.Position = UDim2.new(0.37, 0, 0, 0); nav.Size = UDim2.new(0.38, 0, 1, 0); navLayout.Padding = UDim.new(0, 5)
			local navButtonWidth = math.max(56, math.floor(((size.X - 48) * 0.38 - 15) / 4))
			for _, button in pairs(navButtons) do button.Size = UDim2.fromOffset(navButtonWidth, 44); button.TextSize = math.clamp(navButtonWidth * 0.14, 9, 11) end
			birdBadge.Visible = false
			wantedBox.Size = UDim2.fromOffset(144, 53); wantedBox.Position = UDim2.new(1, -159, 0.5, 0)
			controls.Visible = false
		else
		headerHolder.Position = UDim2.new(0.5, 0, 0, 12)
			nav.Position = UDim2.new(0.34, 0, 0, 0); nav.Size = UDim2.new(0.35, 0, 1, 0); navLayout.Padding = UDim.new(0, 10)
			for page, button in pairs(navButtons) do button.Size = UDim2.fromOffset(page == "UPGRADES" and 126 or 103, 50); button.TextSize = 14 end
			points.Position = UDim2.new(0.158, 0, 0.5, 0); points.Size = UDim2.fromOffset(215, 49)
			logoTop.TextSize = 20; logoTop.Position = UDim2.fromOffset(18, 10); logoTop.Size = UDim2.fromOffset(152, 27)
			logoBottom.TextSize = 24; logoBottom.Position = UDim2.fromOffset(18, 37); logoBottom.Size = UDim2.fromOffset(106, 31)
			pointsPlate.FeatherCoin.Size = UDim2.fromOffset(35, 35); pointsPlate.FeatherCoin.Position = UDim2.fromOffset(8, 7)
			pointsCaption.TextSize = 10; pointsCaption.Position = UDim2.fromOffset(54, 4)
			pointsPlate.Value.Position = UDim2.fromOffset(54, 18); pointsPlate.Value.Size = UDim2.new(1, -62, 0, 26); pointsPlate.Value.TextSize = 21
			birdBadge.Visible = true; birdBadge.Position = UDim2.new(0.724, 0, 0.5, 0)
			wantedBox.Size = UDim2.fromOffset(164, 59); wantedBox.Position = UDim2.new(1, -187, 0.5, 0)
			controls.Visible = true
		end
		if compact then
			modal.AnchorPoint = Vector2.new(0.5, 0.5)
			modal.Position = UDim2.fromScale(0.5, 0.5)
		end
	end

	local function update()
		returnButton.Visible=self.Started
		returnButton.Text=(player:GetAttribute("Wanted") or 0)>0 and "ESCAPE TO RETURN" or "RETURN TO NEST [H]"
		local points = tonumber(player:GetAttribute("Points")) or 0
		pointsValue.Text = tostring(points)
		pointsPill.Text = tostring(points) .. " BIRD POINTS"
		local wanted = math.clamp(tonumber(player:GetAttribute("Wanted")) or 0, 0, 5)
		wantedValue.Text = string.gsub(string.rep("★ ", wanted) .. string.rep("☆ ", 5 - wanted), "%s+$", "")
		local birdNameNow = player:GetAttribute("EquippedBird") or "Pigeon"
		local bird = config.Birds[birdNameNow] or config.Birds.Pigeon
		birdName.Text = string.upper(bird.DisplayName) .. "  |  EQUIPPED"
		birdLetter.Text = string.sub(string.upper(bird.DisplayName), 1, 1)
		birdGlyph.BackgroundColor3 = bird.Color
		for stat, widget in pairs(barWidgets) do
			local raw = stat == "Health" and (tonumber(player:GetAttribute("Health")) or 100) or (tonumber(player:GetAttribute(stat)) or 100)
			local maximum = stat == "Health" and (tonumber(player:GetAttribute("MaxHealth")) or 100) or 100
			local value = math.clamp(raw / maximum, 0, 1)
			widget.Fill.Size = UDim2.fromScale(value, 1)
			widget.Value.Text = tostring(math.floor(value * 100 + 0.5)) .. "%"
		end
		local remaining = math.max(0, self.CooldownEnds - os.clock())
		dropStatus.Text = remaining > 0 and string.format("COOLDOWN  %.1fs", remaining) or (lastMultiplier and ("READY  |  LAST HIT x" .. tostring(lastMultiplier)) or "READY  |  HEIGHT BUILDS MULTIPLIER")
	end

	local elapsed = 0
	RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.12 then
			elapsed = 0
			update()
		end
	end)
	local camera = workspace.CurrentCamera
	if camera then
		local function refreshLayout()
			viewport = root.AbsoluteSize
			layoutFor(viewport)
		end
		refreshLayout()
		task.defer(refreshLayout)
		root:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshLayout)
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshLayout)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.B and self.Started then
			if self.ModalOpen then closeModal() else redraw("SHOP") end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			if self.ModalOpen then closeModal() end
		end
	end)
	return self
end

return UIController
