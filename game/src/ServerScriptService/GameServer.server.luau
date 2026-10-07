-- Bird City MVP. Server owns world state, rewards, purchases, and damage.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ImpactService = require(script.Parent.Services.ImpactService)
local ThreatService = require(script.Parent.Services.ThreatService)
local ProgressionSchema = require(script.Parent.Services.ProgressionSchema)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local WorldBuilder = require(script.Parent.Services.WorldBuilder)
local PopulationService = require(script.Parent.Services.PopulationService)
local HubService = require(script.Parent.Services.HubService)
local BirdVisualService = require(script.Parent.Services.BirdVisualService)

Players.CharacterAutoLoads = true
local store
pcall(function() store = DataStoreService:GetDataStore("BirdCity_Player_v1") end)
local remotes = ReplicatedStorage:FindFirstChild("BirdRemotes") or Instance.new("Folder")
remotes.Name = "BirdRemotes"; remotes.Parent = ReplicatedStorage
local action = remotes:FindFirstChild("Action") or Instance.new("RemoteEvent")
action.Name = "Action"; action.Parent = remotes
local feedback = remotes:FindFirstChild("Feedback") or Instance.new("RemoteEvent")
feedback.Name = "Feedback"; feedback.Parent = remotes

local function folder(parent, name)
	local value = parent:FindFirstChild(name) or Instance.new("Folder")
	value.Name = name; value.Parent = parent; return value
end
local world = folder(workspace, "BirdCity")
local citizens = folder(world, "Citizens")
local policeFolder = folder(world, "AnimalControl")
local dogs = folder(world, "Dogs")
local foodFolder = folder(world, "Food")
local effects = folder(world, "Effects")

local function label(parent, text, color)
	local gui = Instance.new("BillboardGui"); gui.Name = "NameTag"; gui.Size = UDim2.fromOffset(140, 30)
	gui.StudsOffset = Vector3.new(0, 3.3, 0); gui.AlwaysOnTop = true; gui.Parent = parent
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextStrokeTransparency = 0.5
	t.TextColor3 = color; t.Text = text; t.Parent = gui
end

-- Build versioned geometry once; existing combat, currency, and UI contracts stay intact.
WorldBuilder.Build(world)

local function makeHumanoidModel(parent, name, pos, kind, color)
	local model=Instance.new("Model"); model.Name=name; model:SetAttribute("NPCType",kind); model.Parent=parent
	local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Size=Vector3.new(2,2,1); root.Position=pos+Vector3.new(0,3,0); root.Transparency=1; root.CanCollide=true; root.Anchored=false; root.Parent=model
	local torso=Instance.new("Part"); torso.Name="Torso"; torso.Size=Vector3.new(2,2.2,1); torso.Position=root.Position; torso.Color=color; torso.Anchored=false; torso.CanCollide=false; torso.Parent=model
	local head=Instance.new("Part"); head.Name="Head"; head.Shape=Enum.PartType.Ball; head.Size=Vector3.new(1.5,1.3,1.3); head.Position=root.Position+Vector3.new(0,1.7,0); head.Color=Color3.fromRGB(255,207,165); head.Anchored=false; head.CanCollide=false; head.Parent=model
	for _,pair in ipairs({{root,torso},{torso,head}}) do local w=Instance.new("WeldConstraint"); w.Part0=pair[1];w.Part1=pair[2];w.Parent=pair[1] end
	local hum=Instance.new("Humanoid"); hum.DisplayName=name; hum.HipHeight=1; hum.MaxHealth=100; hum.Health=100; hum.WalkSpeed=kind=="Dog" and 15 or 9; hum.Parent=model
	model.PrimaryPart=root
	if kind~="Dog" then label(head,name,kind=="AnimalControl" and Color3.fromRGB(110,190,255) or Color3.fromRGB(255,255,255)) end
	return model,hum,root,head
end

local function spawnPolice(player)
	if #policeFolder:GetChildren()>=5 then return end
	local idx=#policeFolder:GetChildren()+1
	local position=Vector3.new(115,0,400)
	local playerRoot=player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local closest=math.huge
	for _,marker in ipairs(world.Gameplay.AnimalControlSpawns:GetChildren()) do
		local distance=playerRoot and (marker.Position-playerRoot.Position).Magnitude or math.huge
		if distance<closest then closest=distance;position=marker.Position end
	end
	local model,hum,root=makeHumanoidModel(policeFolder,"BirdCatcher_"..idx,position,"AnimalControl",Color3.fromRGB(45,155,130))
	ThreatService.StartCatcher(model,hum,root,feedback)
end

local function makeDog(pos,index)
	local dog,hum,root=makeHumanoidModel(dogs,"CityDog_"..index,pos,"Dog",Color3.fromRGB(176,123,75))
	local muzzle=Instance.new("Part");muzzle.Name="Muzzle";muzzle.Size=Vector3.new(0.8,0.65,1);muzzle.Position=dog.Head.Position+Vector3.new(0,-0.25,-0.75);muzzle.Color=Color3.fromRGB(95,65,48);muzzle.Anchored=false;muzzle.CanCollide=false;muzzle.Parent=dog
	local w=Instance.new("WeldConstraint");w.Part0=dog.Head;w.Part1=muzzle;w.Parent=dog.Head
	ThreatService.StartDog(dog,hum,root)
	return dog
end
PopulationService.Start(world,makeHumanoidModel,makeDog)

local function spawnFood(name, index, position)
	local data=Config.Food[name];local item=Instance.new("Part");item.Name=name;item.Shape=data.Shape;item.Size=Vector3.new(3,3,3);item.Position=position;item.Anchored=true;item.CanCollide=false;item.Color=data.Color;item.Material=Enum.Material.Neon;item:SetAttribute("FoodType",name);item.Parent=foodFolder
	local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Collect";prompt.ObjectText=name;prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.HoldDuration=0;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=item
	local used=false
	prompt.Triggered:Connect(function(player)
		if used then return end;used=true;prompt.Enabled=false
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health<=0 or (root.Position-item.Position).Magnitude>prompt.MaxActivationDistance+2 then
			used=false;prompt.Enabled=true
			return
		end
		local stat=data.Stat;player:SetAttribute(stat,math.min(100,(player:GetAttribute(stat) or 0)+data.Amount));feedback:FireClient(player,"Toast",name.." collected  •  +"..data.Amount.." "..stat)
		item.Transparency=1;item.CanQuery=false
		task.delay(28,function() if item.Parent then item.Transparency=0;item.CanQuery=true;prompt.Enabled=true;used=false end end)
	end)
end
if #foodFolder:GetChildren()==0 then
	local configured={}
	for _,tag in ipairs({"FoodSpawn","WaterSpawn"}) do
		for _,marker in ipairs(CollectionService:GetTagged(tag)) do
			if marker:IsA("BasePart") and marker:IsDescendantOf(workspace) and Config.Food[marker:GetAttribute("FoodType")] then configured[marker]=true end
		end
	end
	for marker in pairs(configured) do spawnFood(marker:GetAttribute("FoodType"),0,marker.Position) end
end
if #foodFolder:GetChildren()==0 then warn("BirdCity: no valid food/water spawn markers were found") end

local function setBird(character, birdName, upgrades, preserveHealth)
	local cfg=Config.Birds[birdName] or Config.Birds.Pigeon
	local root=character:WaitForChild("HumanoidRootPart",8);local hum=character:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return nil end
	local previousHealth=hum.Health
	local healthLevel=upgrades and tonumber(upgrades.Health) or 0
	hum.MaxHealth=cfg.Health+healthLevel*Config.Upgrades.Health.Step;hum.Health=preserveHealth and math.min(previousHealth,hum.MaxHealth) or hum.MaxHealth;hum.WalkSpeed=0;hum.JumpPower=0;hum.AutoRotate=false
	for _,d in ipairs(character:GetDescendants()) do if d:IsA("BasePart") and d~=root then d.Transparency=1;d.CanCollide=false;d.CastShadow=false elseif d:IsA("Accessory") then d:Destroy() end end
	local old=character:FindFirstChild("BirdVisual");if old then old:Destroy() end
	if BirdVisualService.Mount(character,birdName,root) then
		character:SetAttribute("BirdName",birdName)
		return hum.MaxHealth
	end
	local visual=Instance.new("Model");visual.Name="BirdVisual";visual.Parent=character
	local function feather(n,size,offset,color,shape)
		local p=Instance.new("Part");p.Name=n;p.Size=size;p.Shape=shape or Enum.PartType.Ball;p.Color=color or cfg.Color;p.Material=Enum.Material.SmoothPlastic;p.CanCollide=false;p.Massless=true;p.Anchored=false;p.CFrame=root.CFrame*CFrame.new(offset);p.Parent=visual
		local w=Instance.new("WeldConstraint");w.Part0=root;w.Part1=p;w.Parent=p;return p
	end
	feather("Body",Vector3.new(2.5,1.8,3),Vector3.new(0,0,0),cfg.Color)
	feather("Head",Vector3.new(1.35,1.25,1.35),Vector3.new(0,0.8,-1.35),cfg.Color)
	feather("Beak",Vector3.new(0.55,0.4,0.85),Vector3.new(0,0.65,-2.2),Color3.fromRGB(255,177,62),Enum.PartType.Wedge)
	feather("LeftWing",Vector3.new(0.45,0.32,2.4),Vector3.new(-1.35,0.15,0.1),cfg.Color)
	feather("RightWing",Vector3.new(0.45,0.32,2.4),Vector3.new(1.35,0.15,0.1),cfg.Color)
	feather("Tail",Vector3.new(1.1,0.35,1.7),Vector3.new(0,0.3,1.8),cfg.Color,Enum.PartType.Wedge)
	for _,side in ipairs({-1,1}) do local eye=feather("Eye",Vector3.new(0.22,0.22,0.12),Vector3.new(side*0.48,0.98,-1.83),Color3.fromRGB(30,30,35));eye.Material=Enum.Material.Neon end
	character:SetAttribute("BirdName",birdName)
	return hum.MaxHealth
end

local profiles={}
HubService.Bind(world,profiles,feedback)
local function sync(player)
	local profile=profiles[player];if not profile then return end
	local ls=player:FindFirstChild("leaderstats");local points=ls and ls:FindFirstChild("Bird Points");if points then points.Value=profile.Points end
	player:SetAttribute("Points",profile.Points);player:SetAttribute("EquippedBird",profile.Equipped);player:SetAttribute("Wanted",profile.Wanted or 0)
	for key in pairs(Config.Upgrades) do player:SetAttribute("Upgrade_"..key,profile.Upgrades[key] or 0) end
	local today=math.floor(os.time()/86400)
	local claimed=profile.DailyLastClaimDay==today
	local nextDay=claimed and profile.DailyStreak or (profile.DailyLastClaimDay==today-1 and (profile.DailyStreak%7)+1 or 1)
	player:SetAttribute("DailyReady",not claimed);player:SetAttribute("DailyClaimedDay",claimed and profile.DailyStreak or 0)
	player:SetAttribute("DailyNextDay",nextDay);player:SetAttribute("DailyStreak",profile.DailyStreak)
	local bird=Config.Birds[profile.Equipped] or Config.Birds.Pigeon
	player:SetAttribute("MaxHealth",bird.Health+(profile.Upgrades.Health or 0)*Config.Upgrades.Health.Step)
	player:SetAttribute("BodyPower",bird.BodyPower)
	for name in pairs(Config.Birds) do player:SetAttribute("Owned_"..name,profile.Unlocked[name]==true) end
end
local function save(player)
	local p=profiles[player];if not p or not p.Loaded or not p.SaveEnabled or not store then return end
	local key="u_"..player.UserId
	for attempt=1,3 do
		local ok=pcall(function() store:UpdateAsync(key,function(old) old=type(old)=="table" and old or {};ProgressionSchema.Write(old,p,Config.Birds[p.Equipped] or Config.Birds.Pigeon);old.Points=p.Points;old.Unlocked=p.Unlocked;old.Equipped=p.Equipped;old.Upgrades=p.Upgrades;old.DailyStreak=p.DailyStreak;old.DailyLastClaimDay=p.DailyLastClaimDay;return old end) end)
		if ok then return end;task.wait(attempt*1.5)
	end
	warn("BirdCity: could not save data for",player.UserId)
end

Players.PlayerAdded:Connect(function(player)
	local profile={Points=0,Unlocked={Pigeon=true},Equipped="Pigeon",Upgrades={FlightSpeed=0,Stamina=0,Health=0,PoopCooldown=0,Multiplier=0},DailyStreak=0,DailyLastClaimDay=0,Wanted=0,Loaded=false,SaveEnabled=true,LastPoop=-math.huge,LastWantedHit=0}
	local data
	if not store and not RunService:IsStudio() then
		player:Kick("Bird City could not connect to player data. Please rejoin in a moment.")
		return
	end
	if store then
		local loaded=false
		for attempt=1,3 do
			local ok,result=pcall(function() return store:GetAsync("u_"..player.UserId) end)
			if ok then data=result;loaded=true;break end
			task.wait(attempt)
		end
		if not loaded then
			if not RunService:IsStudio() then
				warn("BirdCity: data load failed; refusing to start an unsaved live session",player.UserId)
				player:Kick("Your data could not be loaded safely. Please rejoin in a moment.")
				return
			end
			profile.SaveEnabled=false
			warn("BirdCity: data load failed in Studio; using a temporary test profile")
		end
	end
	if type(data)=="table" then
		profile.Points=math.max(0,math.floor(tonumber(data.Points) or 0))
		if type(data.Unlocked)=="table" then
			for name,unlocked in pairs(data.Unlocked) do
				if Config.Birds[name] and unlocked==true then profile.Unlocked[name]=true end
			end
		end
		if type(data.Upgrades)=="table" then
			for key,spec in pairs(Config.Upgrades) do profile.Upgrades[key]=math.clamp(math.floor(tonumber(data.Upgrades[key]) or 0),0,spec.MaxLevel) end
		end
		profile.DailyStreak=math.clamp(math.floor(tonumber(data.DailyStreak) or 0),0,7)
		profile.DailyLastClaimDay=math.max(0,math.floor(tonumber(data.DailyLastClaimDay) or 0))
		if profile.Unlocked[data.Equipped] then profile.Equipped=data.Equipped end
	end
	profile.Future=ProgressionSchema.Read(data)
	profile.Loaded=true;profiles[player]=profile
	local ls=Instance.new("Folder");ls.Name="leaderstats";ls.Parent=player
	local pts=Instance.new("IntValue");pts.Name="Bird Points";pts.Parent=ls
	for _,name in ipairs({"Health","Hunger","Thirst","Stamina"}) do player:SetAttribute(name,name=="Health" and 100 or 100) end
	sync(player)
	local handledCharacter
	local function onCharacterAdded(character)
		if handledCharacter==character then return end
		handledCharacter=character
		player:SetAttribute("Captured",false)
		profile.Boosting=false
		player:SetAttribute("Stamina",100)
		task.spawn(function()
			local maxHealth=setBird(character,profile.Equipped,profile.Upgrades)
			local humanoid=character:FindFirstChildOfClass("Humanoid")
			if maxHealth and humanoid and player.Character==character then player:SetAttribute("MaxHealth",maxHealth);player:SetAttribute("Health",humanoid.Health) end
		end)
		local characterRoot=character:WaitForChild("HumanoidRootPart",8)
		if characterRoot then profile.LastMovementPosition=characterRoot.Position;profile.LastMovementSampleAt=os.clock() end
		local hum=character:WaitForChild("Humanoid")
		hum.Died:Connect(function() profile.Wanted=0;sync(player);task.delay(Players.RespawnTime+0.2,function() if player.Parent then player:SetAttribute("Hunger",math.max(40,player:GetAttribute("Hunger") or 100));player:SetAttribute("Thirst",math.max(40,player:GetAttribute("Thirst") or 100)) end end) end)
		hum.HealthChanged:Connect(function(value) player:SetAttribute("Health",math.max(0,value)) end)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then task.spawn(onCharacterAdded,player.Character) end
end)
Players.PlayerRemoving:Connect(function(player) save(player);profiles[player]=nil end)
task.spawn(function()
	while true do
		task.wait(60)
		for _,player in ipairs(Players:GetPlayers()) do
			if profiles[player] then task.spawn(save,player) end
		end
	end
end)
game:BindToClose(function()
	local players=Players:GetPlayers()
	if #players==0 then return end
	local pending=#players
	local completed=Instance.new("BindableEvent")
	for _,player in ipairs(players) do
		task.spawn(function()
			save(player)
			pending-=1
			if pending==0 then completed:Fire() end
		end)
	end
	local deadline=os.clock()+25
	task.delay(25,function() if pending>0 and completed.Parent then completed:Fire() end end)
	while pending>0 and os.clock()<deadline do completed.Event:Wait() end
	completed:Destroy()
end)

local function addWanted(player,amount)
	local p=profiles[player];if not p then return end;p.Wanted=math.clamp((p.Wanted or 0)+amount,0,5);p.LastWantedHit=os.clock();sync(player)
	while #policeFolder:GetChildren()<math.min(5,p.Wanted) do spawnPolice(player) end
end
local function doPoop(player)
	local p=profiles[player];local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart");local hum=character and character:FindFirstChildOfClass("Humanoid")
	if not p or not root or not hum or hum.Health<=0 or player:GetAttribute("Captured") then return end
	local bird=Config.Birds[p.Equipped] or Config.Birds.Pigeon
	local now=os.clock()
	local sampleAge=math.max(0,now-(p.LastMovementSampleAt or now))
	local maxMovement=135*bird.Speed*(1+(p.Upgrades.FlightSpeed or 0)*Config.Upgrades.FlightSpeed.Step)*sampleAge+45
	if p.LastMovementPosition and (root.Position-p.LastMovementPosition).Magnitude>maxMovement then
		p.MovementSuspiciousUntil=now+4
	end
	if now<(p.MovementSuspiciousUntil or 0) then
		feedback:FireClient(player,"Toast","Flight data is settling. Try again in a moment.")
		return
	end
	local cooldown=math.max(Config.Upgrades.PoopCooldown.Minimum,(bird.Cooldown or 1.5)-(p.Upgrades.PoopCooldown or 0)*Config.Upgrades.PoopCooldown.Step)
	if os.clock()-p.LastPoop<cooldown then return end
	p.LastPoop=os.clock()
	BirdVisualService.Signal(character,"Poop")
	local dropHeight=root.Position.Y
	local pellet=Instance.new("Part");pellet.Name="BirdDrop";pellet.Shape=Enum.PartType.Ball;pellet.Size=Vector3.new(0.85,0.85,0.85);pellet.Color=Color3.fromRGB(245,245,222);pellet.Material=Enum.Material.SmoothPlastic;pellet.CanCollide=false;pellet.Position=root.Position+Vector3.new(0,-2,0);pellet.Parent=world
	pellet:SetNetworkOwner(nil)
	ImpactService.PlaySound("Release", root)
	ImpactService.PlaySound("Projectile", pellet)
	local owner=Instance.new("ObjectValue");owner.Name="Owner";owner.Value=player;owner.Parent=pellet
	pellet.AssemblyLinearVelocity=root.AssemblyLinearVelocity+Vector3.new(0,-8,0)
	local supportPart
	local supportParams=RaycastParams.new();supportParams.FilterType=Enum.RaycastFilterType.Exclude;supportParams.FilterDescendantsInstances={character}
	local supportResult=workspace:Raycast(root.Position,Vector3.new(0,-5,0),supportParams)
	if supportResult and supportResult.Instance:IsA("BasePart") and supportResult.Distance<4 then supportPart=supportResult.Instance end
	local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude;rayParams.FilterDescendantsInstances=supportPart and {character,pellet,supportPart,effects} or {character,pellet,effects}
	local done=false
	local function resolveImpact(hit, position, normal)
		if done or not hit or not hit.Parent then return end
		if hit==supportPart or hit.Name=="BirdRoost" or (character and hit:IsDescendantOf(character)) then return end
		if hit:IsDescendantOf(effects) or hit.Name=="BirdDrop" then return end
		position = position or pellet.Position
		normal = normal or (pellet.AssemblyLinearVelocity.Magnitude > 0.01 and -pellet.AssemblyLinearVelocity.Unit or Vector3.yAxis)
		local model=hit:FindFirstAncestorOfClass("Model")
		if model and model:GetAttribute("NPCType")=="Citizen" then
			done=true
			local splat = ImpactService.Splat(hit, position, normal, effects)
			local headshot=hit.Name=="Head";local height=math.max(0,dropHeight-model:GetPivot().Position.Y)
			local mult=1;for _,tier in ipairs(Config.Scoring.Tiers) do if height<=tier.Height then mult=tier.Multiplier;break end end
			mult+= (p.Upgrades.Multiplier or 0)*Config.Upgrades.Multiplier.Step
			local reward=math.floor((Config.Scoring.BaseHit+(headshot and Config.Scoring.HeadshotBonus or 0))*mult)
			local profile=profiles[player];if profile then profile.Points+=reward;sync(player);feedback:FireClient(player,"Hit",{Points=reward,Multiplier=mult,Headshot=headshot,Height=math.floor(height)});addWanted(player,Config.Scoring.WantedPerHit) end
			PopulationService.Flee(model)
			ImpactService.PlaySound(headshot and "Headshot" or "TargetHit", splat)
			pellet:Destroy()
		elseif (model and (Players:GetPlayerFromCharacter(model) or model:GetAttribute("NPCType"))) or hit:IsA("Terrain") or (hit:IsA("BasePart") and hit.CanCollide) then
			-- City player hits are visual only; PvP remains opt-in for a future arena.
			done=true;ImpactService.Splat(hit, position, normal, effects);pellet:Destroy()
		end
	end
	pellet.Touched:Connect(resolveImpact)
	local previousPosition=pellet.Position
	local rayConnection
	rayConnection=RunService.Heartbeat:Connect(function()
		if done or not pellet.Parent then if rayConnection then rayConnection:Disconnect() end;return end
		local currentPosition=pellet.Position;local movement=currentPosition-previousPosition
		if movement.Magnitude>0 then local result=workspace:Raycast(previousPosition,movement,rayParams);if result then resolveImpact(result.Instance,result.Position,result.Normal) end end
		previousPosition=currentPosition
	end)
	Debris:AddItem(pellet,Config.Poop.ProjectileLifetime)
	feedback:FireClient(player,"Cooldown",cooldown)
end

action.OnServerEvent:Connect(function(player,verb,value)
	local profile=profiles[player]
	if not profile or type(verb)~="string" then return end
	local now=os.clock()
	if now-(profile.ActionWindowStart or 0)>=1 then
		profile.ActionWindowStart=now
		profile.ActionCount=0
	end
	profile.ActionCount=(profile.ActionCount or 0)+1
	if profile.ActionCount>20 then return end
	if verb=="ReturnToHub" then HubService.RequestReturn(player,profile,feedback)
	elseif verb=="Poop" then doPoop(player)
	elseif verb=="Boost" then
		local p=profiles[player];if p and type(value)=="boolean" then p.Boosting=value end
	elseif verb=="BuyBird" or verb=="EquipBird" then
		local p=profiles[player];if not p or type(value)~="string" then return end
		local cfg=Config.Birds[value];if not cfg then return end
		if verb=="BuyBird" then
			if cfg.PremiumPlaceholder then feedback:FireClient(player,"Toast",cfg.DisplayName.." is coming soon.");return end
			if p.Unlocked[value] then feedback:FireClient(player,"Toast",cfg.DisplayName.." is already in your flock.");return end
			if p.Points<cfg.Cost then feedback:FireClient(player,"Toast","You need "..(cfg.Cost-p.Points).." more Bird Points.");return end
			p.Points-=cfg.Cost;p.Unlocked[value]=true
		end
		if not p.Unlocked[value] then feedback:FireClient(player,"Toast","Unlock "..cfg.DisplayName.." in the Bird Shop first.");return end
		p.Equipped=value;sync(player);if player.Character then setBird(player.Character,value,p.Upgrades,true) end;feedback:FireClient(player,"Toast",cfg.DisplayName.." equipped!")
	elseif verb=="Upgrade" then
		local p=profiles[player];if not p or type(value)~="string" then return end
		local spec=Config.Upgrades[value];if not spec then return end
		local level=p.Upgrades[value] or 0
		if level>=spec.MaxLevel then feedback:FireClient(player,"Toast",spec.DisplayName.." is already maxed.");return end
		local cost=spec.Costs[level+1]
		if p.Points<cost then feedback:FireClient(player,"Toast","You need "..(cost-p.Points).." more Bird Points.");return end
		p.Points-=cost;p.Upgrades[value]=level+1;sync(player)
		if value=="Health" and player.Character then
			local maxHealth=setBird(player.Character,p.Equipped,p.Upgrades,true)
			if maxHealth then player:SetAttribute("MaxHealth",maxHealth);player:SetAttribute("Health",player.Character.Humanoid.Health) end
		end
		feedback:FireClient(player,"Toast",spec.DisplayName.." upgraded to level "..tostring(level+1).."!")
	elseif verb=="ClaimDaily" then
		local p=profiles[player];if not p then return end
		local today=math.floor(os.time()/86400)
		if p.DailyLastClaimDay==today then feedback:FireClient(player,"Toast","Your daily reward is already claimed.");return end
		local day=p.DailyLastClaimDay==today-1 and (p.DailyStreak%7)+1 or 1
		local reward=Config.DailyRewards[day]
		if not reward then return end
		p.DailyStreak=day;p.DailyLastClaimDay=today;p.Points+=reward;sync(player)
		feedback:FireClient(player,"Toast","Day "..day.." claimed!  +"..reward.." Bird Points")
	end
end)

-- Survival stats, wanted decay, and server-side movement ceilings.
local clock=0
RunService.Heartbeat:Connect(function(dt)
	clock+=dt;if clock<1 then return end;local elapsed=clock;clock=0
	for _,player in ipairs(Players:GetPlayers()) do
		local hunger=math.max(0,(player:GetAttribute("Hunger") or 100)-Config.Survival.HungerDrain*elapsed)
		local thirst=math.max(0,(player:GetAttribute("Thirst") or 100)-Config.Survival.ThirstDrain*elapsed)
		local p=profiles[player]
		local staminaLevel=p and (p.Upgrades.Stamina or 0) or 0
		local equippedBird=p and Config.Birds[p.Equipped]
		local staminaFactor=equippedBird and equippedBird.Stamina or 1
		local staminaDrain=Config.Survival.StaminaDrain/staminaFactor*(1-staminaLevel*Config.Upgrades.Stamina.DrainStep)
		local staminaRegen=Config.Survival.StaminaRegen*staminaFactor*(1+staminaLevel*Config.Upgrades.Stamina.RegenStep)
		local stamina=math.clamp((player:GetAttribute("Stamina") or 100)+(p and p.Boosting and -staminaDrain*elapsed or staminaRegen*elapsed),0,100)
		if p and stamina<=0 then p.Boosting=false end
		player:SetAttribute("Hunger",hunger);player:SetAttribute("Thirst",thirst);player:SetAttribute("Stamina",stamina)
		if p and p.Wanted>0 and os.clock()-p.LastWantedHit>24 then p.Wanted=math.max(0,p.Wanted-1);p.LastWantedHit=os.clock();sync(player) end
		local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health>0 and (hunger<=0 or thirst<=0) then hum:TakeDamage(1) end
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart");local cfg=p and Config.Birds[p.Equipped]
		if root and cfg then
			local speedLevel=p.Upgrades.FlightSpeed or 0
			local speedMultiplier=1+speedLevel*Config.Upgrades.FlightSpeed.Step
			if root.AssemblyLinearVelocity.Magnitude>135*cfg.Speed*speedMultiplier then root.AssemblyLinearVelocity=root.AssemblyLinearVelocity.Unit*135*cfg.Speed*speedMultiplier end
			local now=os.clock()
			if p.LastMovementPosition then
				local moved=(root.Position-p.LastMovementPosition).Magnitude
				if moved>135*cfg.Speed*speedMultiplier*elapsed+45 then p.MovementSuspiciousUntil=now+4 end
			end
			p.LastMovementPosition=root.Position
			p.LastMovementSampleAt=now
		end
		if p then
			local currentDay=math.floor(os.time()/86400)
			if p.LastSeenUtcDay~=currentDay then p.LastSeenUtcDay=currentDay;sync(player) end
		end
	end
end)
