-- Reusable native Roblox UI primitives. UITheme is the single source of visual tokens.
local TweenService = game:GetService("TweenService")
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("UITheme"))

local Components = {}
local C = Theme.Color

function Components.New(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

function Components.Corner(instance, radius)
	return Components.New("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radius.Medium) }, instance)
end

function Components.Stroke(instance, color, thickness, transparency)
	return Components.New("UIStroke", {
		Color = color or C.Ink,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, instance)
end

function Components.Gradient(instance, topColor, bottomColor, rotation)
	return Components.New("UIGradient", {
		Color = ColorSequence.new(topColor, bottomColor),
		Rotation = rotation or 90,
	}, instance)
end

function Components.Label(parent, text, size, color, bold, properties)
	local options = {
		Name = "Label",
		BackgroundTransparency = 1,
		Text = text or "",
		TextColor3 = color or C.Ink,
		TextSize = size or 16,
		Font = bold == false and Enum.Font.GothamMedium or Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = false,
		RichText = false,
		BorderSizePixel = 0,
	}
	for key, value in pairs(properties or {}) do
		options[key] = value
	end
	return Components.New("TextLabel", options, parent)
end

function Components.Panel(parent, name, size, position, color, shadow)
	local holder = Components.New("Frame", {
		Name = name .. "Holder",
		BackgroundTransparency = 1,
		Size = size,
		Position = position,
		BorderSizePixel = 0,
	}, parent)
	if shadow ~= false then
		local shade = Components.New("Frame", {
			Name = "Shadow",
			BackgroundColor3 = C.InkLight,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 1,
		}, holder)
		Components.Corner(shade, Theme.Radius.Large)
	end
	local plate = Components.New("Frame", {
		Name = name,
		BackgroundColor3 = color or C.Cream,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	}, holder)
	Components.Corner(plate, Theme.Radius.Large)
	Components.Stroke(plate, C.Ink, 3)
	return holder, plate
end

function Components.Button(parent, name, text, size, color, textColor)
	local button = Components.New("TextButton", {
		Name = name,
		Size = size,
		BackgroundColor3 = color or C.Blue,
		Text = text or "",
		TextColor3 = textColor or C.White,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Selectable = true,
		Active = true,
		ZIndex = 2,
	}, parent)
	Components.Corner(button, Theme.Radius.Medium)
	Components.Stroke(button, C.Ink, 2)
	local resting = button.BackgroundColor3
	local function animate(properties)
		TweenService:Create(button, Theme.Motion.Fast, properties):Play()
	end
	button.MouseEnter:Connect(function()
		if button.Active then
			resting = button.BackgroundColor3
			animate({ BackgroundColor3 = resting:Lerp(C.White, 0.14) })
		end
	end)
	button.MouseLeave:Connect(function()
		animate({ BackgroundColor3 = resting })
	end)
	button.MouseButton1Down:Connect(function()
		if button.Active then
			animate({ BackgroundColor3 = button.BackgroundColor3:Lerp(C.Ink, 0.1) })
		end
	end)
	button.MouseButton1Up:Connect(function()
		if button.Active then
			animate({ BackgroundColor3 = resting:Lerp(C.White, 0.14) })
		end
	end)
	return button
end

function Components.DisableButton(button, text)
	button.Active = false
	button.Selectable = false
	button.Text = text or "LOCKED"
	button.BackgroundColor3 = C.Muted
	button.TextColor3 = C.Cream
	local outline = button:FindFirstChildOfClass("UIStroke")
	if outline then outline.Transparency = 0.35 end
end

return Components
