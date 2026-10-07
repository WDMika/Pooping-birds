-- Bounded local presentation primitives; caller supplies server-approved result/location.
local TweenService = game:GetService("TweenService")
local Definitions = require(game.ReplicatedStorage.Shared.ContentDefinitions).VFX
local VFX = {}; VFX.__index = VFX
local Colors = {PoopSplat=Color3.fromRGB(245,245,222),Headshot=Color3.fromRGB(250,120,41),Wanted=Color3.fromRGB(235,79,71),LegendaryReward=Color3.fromRGB(255,199,48),EggHatch=Color3.fromRGB(255,247,219),PvP=Color3.fromRGB(107,199,232)}
function VFX.new()
	local folder = Instance.new("Folder"); folder.Name = "PB_LocalVFX"; folder.Parent = workspace
	return setmetatable({Folder=folder,Active={},Counts={},Instances=0,Reduced=false,Destroyed=false},VFX)
end
function VFX:SetReducedEffects(enabled) self.Reduced = enabled == true end
function VFX:_Remove(record)
	if not self.Active[record] then return end
	self.Active[record] = nil; self.Counts[record.Name] -= 1; self.Instances -= record.Cost
	for _, tween in record.Tweens do tween:Cancel() end
	for _, connection in record.Connections do connection:Disconnect() end
	for _, object in record.Objects do object:Destroy() end
end
function VFX:_Begin(name, position, cost)
	local spec = Definitions[name]
	if self.Destroyed or not spec or typeof(position) ~= "Vector3" then return nil end
	if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z or position.Magnitude > 1e6 then return nil end
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position-position).Magnitude > spec.Range then return nil end
	if (self.Counts[name] or 0) >= spec.MaxActive or self.Instances + cost > 96 then return nil end
	local record={Name=name,Cost=cost,Objects={},Tweens={},Connections={}}
	self.Active[record]=true; self.Counts[name]=(self.Counts[name] or 0)+1; self.Instances+=cost
	task.delay(spec.Lifetime,function()self:_Remove(record)end)
	return record
end
function VFX:Emit(name, position, payload)
	payload = payload or {}
	local count = name == "ScorePopup" and 1 or self.Reduced and 2 or name == "PoopSplat" and 1 or 8
	local record = self:_Begin(name, position, name == "ScorePopup" and 3 or count)
	if not record then return false end
	for i=1,count do
		local part=Instance.new("Part");part.Name=Definitions[name].Name;part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
		part.Material=Enum.Material.Neon;part.Color=Colors[name] or Color3.fromRGB(107,199,232);part.Shape=Enum.PartType.Ball;part.Size=Vector3.one*.18;part.Position=position;part.Parent=self.Folder
		table.insert(record.Objects,part)
		if name=="ScorePopup" then
			part.Transparency=1
			local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(160,44);gui.AlwaysOnTop=false;gui.MaxDistance=120;gui.Parent=part
			local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.Text=string.sub(tostring(payload.Text or ""),1,40);label.Font=Enum.Font.GothamBold;label.TextSize=24;label.TextColor3=Color3.fromRGB(255,199,48);label.TextStrokeTransparency=.4;label.Parent=gui
		elseif name=="PoopSplat" then
			part.Material=Enum.Material.SmoothPlastic;part.Size=Vector3.new(1.6,.12,1.3)
			local normal=typeof(payload.Normal)=="Vector3" and payload.Normal.Magnitude>.001 and payload.Normal.Unit or Vector3.yAxis
			part.CFrame=CFrame.lookAt(position+normal*.08,position+normal)*CFrame.Angles(math.pi/2,0,0)
		end
		local angle=i/count*math.pi*2
		local target=name=="ScorePopup" and position+Vector3.new(0,2,0) or name=="PoopSplat" and part.Position or position+Vector3.new(math.cos(angle)*2,1,math.sin(angle)*2)
		local tween=TweenService:Create(part,TweenInfo.new(Definitions[name].Lifetime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=target,Transparency=1})
		table.insert(record.Tweens,tween);tween:Play()
	end
	return true
end
function VFX:Trail(name, parent)
	if not parent or not parent:IsA("BasePart") or not parent:IsDescendantOf(workspace) then return nil end
	local record=self:_Begin(name,parent.Position,3);if not record then return nil end
	local a=Instance.new("Attachment");a.Position=Vector3.new(-.4,0,0);a.Parent=parent
	local b=Instance.new("Attachment");b.Position=Vector3.new(.4,0,0);b.Parent=parent
	local trail=Instance.new("Trail");trail.Name=Definitions[name].Name;trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=self.Reduced and .1 or .25;trail.Color=ColorSequence.new(Colors[name] or Color3.fromRGB(107,199,232));trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,1)});trail.Parent=parent
	record.Objects={trail,a,b};record.Connections[1]=parent.AncestryChanged:Connect(function()if not parent:IsDescendantOf(workspace)then self:_Remove(record)end end)
	return function() self:_Remove(record) end
end
function VFX:Destroy()
	self.Destroyed=true
	local active={};for record in self.Active do table.insert(active,record)end
	for _,record in active do self:_Remove(record)end
	self.Folder:Destroy()
end
return VFX
