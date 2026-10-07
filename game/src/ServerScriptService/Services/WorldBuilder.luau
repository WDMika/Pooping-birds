-- Deterministic, replaceable blockout kit. Only generated geometry is rebuilt.
local CollectionService = game:GetService("CollectionService")
local WorldConfig = require(game.ReplicatedStorage.Shared.WorldConfig)
local Builder = {}
local C = {
	Grass=Color3.fromRGB(109,178,113), Rock=Color3.fromRGB(116,100,88), Earth=Color3.fromRGB(140,108,77),
	Road=Color3.fromRGB(57,66,79), Walk=Color3.fromRGB(213,210,195), Roof=Color3.fromRGB(77,91,110),
	Glass=Color3.fromRGB(139,206,226), Gold=Color3.fromRGB(251,202,85), Wood=Color3.fromRGB(153,102,62),
}
local function folder(parent,name)
	local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f
end
local function model(parent,name)
	local m=Instance.new("Model");m.Name=name;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=parent;return m
end
local function part(parent,name,size,pos,color,material,shape,collide)
	local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=pos;p.Color=color or C.Roof
	p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=collide~=false
	p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	if shape then p.Shape=shape end;p.Parent=parent;return p
end
local function sign(parent, text, pos, color, width)
	local p=part(parent,"Sign_"..text,Vector3.new(width or 28,8,1),pos,color or C.Road,nil,nil,false)
	local gui=Instance.new("SurfaceGui");gui.Name="Label";gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=18;gui.Parent=p
	local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold;t.Text=text;t.TextScaled=true;t.TextColor3=Color3.fromRGB(255,248,222);t.TextWrapped=true;t.Parent=gui
	local back=gui:Clone();back.Name="BackLabel";back.Face=Enum.NormalId.Back;back.Parent=p
	return p
end
local function marker(parent,name,pos,tag,attrs)
	local p=part(parent,name,Vector3.one,pos,C.Gold,nil,nil,false);p.Transparency=1;p.CanQuery=false
	for key,value in pairs(attrs or {}) do p:SetAttribute(key,value) end
	CollectionService:AddTag(p,tag);return p
end
local function tree(parent,pos,scale)
	scale=scale or 1;local m=model(parent,"Tree")
	part(m,"Trunk",Vector3.new(3,19,3)*scale,pos+Vector3.new(0,9.5*scale,0),C.Wood,Enum.Material.Wood)
	part(m,"Canopy",Vector3.new(22,24,22)*scale,pos+Vector3.new(0,26*scale,0),C.Grass,Enum.Material.Grass,Enum.PartType.Ball,false)
end
local function bench(parent,pos)
	local m=model(parent,"Bench");part(m,"Seat",Vector3.new(12,1,4),pos+Vector3.new(0,2,0),C.Wood,Enum.Material.Wood)
	part(m,"Back",Vector3.new(12,4,1),pos+Vector3.new(0,4,1.7),C.Wood,Enum.Material.Wood)
	for _,x in ipairs({-4,4}) do part(m,"Leg",Vector3.new(1,2,3),pos+Vector3.new(x,1,0),C.Road) end
end
local function road(parent,name,pos,length,width,alongX)
	local size=alongX and Vector3.new(length,0.4,width) or Vector3.new(width,0.4,length)
	part(parent,name,size,pos+Vector3.new(0,0.2,0),C.Road,Enum.Material.Asphalt)
	for _,side in ipairs({-1,1}) do
		local off=alongX and Vector3.new(0,0,side*(width/2+6)) or Vector3.new(side*(width/2+6),0,0)
		part(parent,"Sidewalk",alongX and Vector3.new(length,0.8,12) or Vector3.new(12,0.8,length),pos+off+Vector3.new(0,0.4,0),C.Walk,Enum.Material.Concrete)
	end
	part(parent,"CenterLine",alongX and Vector3.new(length,0.06,0.5) or Vector3.new(0.5,0.06,length),pos+Vector3.new(0,0.45,0),C.Gold)
end
local function cylinder(parent,name,diameter,height,pos,color,collide)
	local p=part(parent,name,Vector3.new(height,diameter,diameter),pos,color,nil,Enum.PartType.Cylinder,collide)
	p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2);return p
end
local function building(parent,name,pos,w,d,h,color,style,gameplay)
	local m=model(parent,name);m:SetAttribute("RoofHeight",h);m:SetAttribute("District",parent.Name)
	part(m,"Building",Vector3.new(w,h,d),pos+Vector3.new(0,h/2,0),color,Enum.Material.Concrete)
	part(m,"Roof",Vector3.new(w+3,2,d+3),pos+Vector3.new(0,h+1,0),C.Roof)
	-- Window strips convey floor scale without hundreds of tiny window parts.
	for _,side in ipairs({-1,1}) do
		for band=1,3 do
			part(m,"WindowRibbon",Vector3.new(w-10,math.max(5,h*0.12),0.25),pos+Vector3.new(0,h*(0.23+band*0.18),side*(d/2+0.15)),C.Glass,Enum.Material.Glass,nil,false)
		end
	end
	part(m,"Door",Vector3.new(7,10,0.3),pos+Vector3.new(0,5,-d/2-0.2),C.Road,nil,nil,false)
	if style=="House" then
		local roof=Instance.new("WedgePart");roof.Name="SlopedRoof";roof.Size=Vector3.new(w+6,15,d+6);roof.CFrame=CFrame.new(pos+Vector3.new(0,h+8,0));roof.Color=Color3.fromRGB(170,80,67);roof.Anchored=true;roof.CanTouch=false;roof.Parent=m
		part(m,"Chimney",Vector3.new(5,14,5),pos+Vector3.new(w/3,h+14,0),C.Earth)
	elseif style=="Tower" then
		part(m,"Crown",Vector3.new(w*0.72,18,d*0.72),pos+Vector3.new(0,h+11,0),color)
		part(m,"Antenna",Vector3.new(2,32,2),pos+Vector3.new(0,h+36,0),C.Road,Enum.Material.Metal)
	else
		part(m,"HVAC",Vector3.new(16,7,12),pos+Vector3.new(-w/4,h+5,0),Color3.fromRGB(159,174,176),Enum.Material.Metal)
		if style=="Warehouse" then
			part(m,"RoofPipe",Vector3.new(w*0.7,4,4),pos+Vector3.new(0,h+5,d/4),C.Gold,Enum.Material.Metal)
		else cylinder(m,"WaterTower",12,14,pos+Vector3.new(w/4,h+9,d/5),C.Wood) end
	end
	-- Clear perch opposite roof machinery, useful food and water at rooftop altitude.
	local perchHeight=h+(style=="House" and 18 or (style=="Tower" and 21 or 2))
	part(m,"LandingPerch",Vector3.new(18,1,12),pos+Vector3.new(w/4,perchHeight,-d/3),C.Gold)
	if style=="House" then
		for _,side in ipairs({-1,1}) do part(m,"PerchSupport",Vector3.new(2,13,2),pos+Vector3.new(w/4+side*7,h+11.5,-d/3),C.Wood,Enum.Material.Wood) end
	end
	marker(gameplay.FoodSpawns,name.."RoofFood",pos+Vector3.new(w/4,perchHeight+2,-d/3),"FoodSpawn",{FoodType="Banana",District=parent.Name})
	return m
end
local function hub(world)
	local h=folder(world,"Hub");local origin=WorldConfig.HubCenter
	local landscape=model(h,"FloatingIsland")
	local grass=part(landscape,"GrassSurface",Vector3.new(12,540,420),origin,C.Grass,Enum.Material.Grass,Enum.PartType.Cylinder)
	grass.CFrame=CFrame.new(origin)*CFrame.Angles(0,0,math.pi/2)
	part(landscape,"EarthShelf",Vector3.new(525,65,405),origin-Vector3.new(0,35,0),C.Earth,Enum.Material.Ground,Enum.PartType.Ball)
	part(landscape,"RockTier",Vector3.new(420,100,310),origin-Vector3.new(0,90,0),C.Rock,Enum.Material.Rock,Enum.PartType.Ball)
	part(landscape,"RockTip",Vector3.new(230,120,165),origin-Vector3.new(0,165,0),C.Rock,Enum.Material.Rock,Enum.PartType.Ball)
	for i=1,8 do
		local angle=i*math.pi/4;local pos=origin+Vector3.new(math.cos(angle)*175,-75,math.sin(angle)*130)
		local p=Instance.new("WedgePart");p.Name="RockFacet";p.Size=Vector3.new(80,95,105);p.CFrame=CFrame.new(pos)*CFrame.Angles(0,-angle,0);p.Color=C.Rock;p.Material=Enum.Material.Rock;p.Anchored=true;p.CanTouch=false;p.Parent=landscape
	end
	for i=1,10 do
		local a=i*math.pi/5;local p=part(landscape,"Cloud",Vector3.new(75,20,45),origin+Vector3.new(math.cos(a)*290,-75-(i%3)*18,math.sin(a)*225),Color3.new(1,1,1),nil,Enum.PartType.Ball,false);p.Transparency=0.3;p.CanQuery=false;p.CastShadow=false
	end
	local spawnFolder=folder(h,"SpawnPlaza")
	cylinder(spawnFolder,"Plaza",80,1,origin+Vector3.new(0,6.5,135),C.Walk)
	local spawn=Instance.new("SpawnLocation");spawn.Name="BirdRoost";spawn.Size=Vector3.new(28,1,28);spawn.Position=WorldConfig.SpawnPosition-Vector3.new(0,1,0);spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Transparency=1;spawn.Parent=spawnFolder
	spawn.CFrame=CFrame.new(spawn.Position)*CFrame.Angles(0,math.pi,0)
	marker(spawnFolder,"ReturnDestination",WorldConfig.SpawnPosition+Vector3.new(0,3,0),"HubReturnDestination",{Safe=true})
	sign(spawnFolder,"SKY SANCTUARY",origin+Vector3.new(0,21,109),Color3.fromRGB(48,139,130),55)
	local zones={
		{"BirdShop",-145,-55,"BIRD SHOP",Color3.fromRGB(65,155,208),"SHOP"},
		{"UpgradeArea",-150,45,"UPGRADES",Color3.fromRGB(103,142,95),"UPGRADES"},
		{"RewardArea",-85,120,"DAILY REWARDS",Color3.fromRGB(237,160,65),"DAILY"},
		{"NestArea",150,-15,"YOUR NEST",C.Wood,"BIRDS"},
		{"IncubatorArea",140,90,"INCUBATOR • FUTURE",Color3.fromRGB(108,190,198)},
		{"BreedingArea",60,135,"BREEDING • FUTURE",Color3.fromRGB(194,141,195)},
		{"Leaderboards",-35,-125,"FLOCK RECORDS • FUTURE",C.Road},
		{"SocialArea",85,-100,"FLOCK GARDEN",Color3.fromRGB(61,158,120)},
	}
	for _,z in ipairs(zones) do
		local f=folder(h,z[1]);f:SetAttribute("IntegrationId",z[1]);f:SetAttribute("BackendAvailable",z[6]~=nil)
		local pos=origin+Vector3.new(z[2],7,z[3]);cylinder(f,"ZonePad",58,2,pos,z[5])
		sign(f,z[4],pos+Vector3.new(0,12,-16),z[5],44)
		part(f,"Perch",Vector3.new(38,3,8),pos+Vector3.new(0,4,12),C.Wood,Enum.Material.Wood)
		if z[6] then marker(f,"Interaction",pos+Vector3.new(0,6,12),"HubInteraction",{Page=z[6]}) end
		if z[6] and z[1]~="NestArea" then
			for _,side in ipairs({-1,1}) do part(f,"KioskPost",Vector3.new(2,19,2),pos+Vector3.new(side*19,11,-7),C.Wood,Enum.Material.Wood) end
			part(f,"FeatherCanopy",Vector3.new(48,3,25),pos+Vector3.new(0,21,-7),z[5])
		end
		if z[1]=="NestArea" or z[1]=="BreedingArea" then
			for i=1,6 do
				local a=i*math.pi/3;local twig=part(f,"NestTwig",Vector3.new(20,2,4),pos+Vector3.new(math.cos(a)*14,3,math.sin(a)*14),C.Wood,Enum.Material.Wood);twig.CFrame=CFrame.new(twig.Position)*CFrame.Angles(0,-a+math.pi/2,0)
			end
		end
		if z[1]=="IncubatorArea" then part(f,"EggPlaceholder",Vector3.new(9,13,9),pos+Vector3.new(0,8,0),Color3.fromRGB(246,240,200),nil,Enum.PartType.Ball) end
	end
	local paths=folder(h,"Paths")
	part(paths,"NorthSouthPath",Vector3.new(12,0.6,300),origin+Vector3.new(0,6.4,-15),C.Walk)
	part(paths,"EastWestPath",Vector3.new(360,0.6,12),origin+Vector3.new(0,6.4,0),C.Walk)
	for _,pos in ipairs({Vector3.new(-220,0,-45),Vector3.new(-190,0,-110),Vector3.new(-210,0,80),Vector3.new(200,0,-70),Vector3.new(90,0,-160),Vector3.new(-50,0,-175)}) do tree(landscape,origin+pos+Vector3.new(0,6,0),1.2) end
	for _,pos in ipairs({Vector3.new(-80,0,0),Vector3.new(65,0,-65),Vector3.new(0,0,-80)}) do bench(landscape,origin+pos+Vector3.new(0,6,0)) end
	local launch=folder(h,"LaunchAreas")
	for _,v in ipairs({{"Park",Vector3.new(-250,7,45)}, {"Downtown",Vector3.new(0,7,-210)}, {"Commercial",Vector3.new(250,7,-45)}, {"Industrial",Vector3.new(0,7,210)}}) do
		local m=model(launch,v[1].."Launch");local pos=origin+v[2]
		part(m,"LaunchLedge",Vector3.new(42,2,32),pos,C.Gold)
		sign(m,"FLY TO "..string.upper(v[1]),pos+Vector3.new(0,10,-10),Color3.fromRGB(50,130,160),38)
		marker(m,"FlightLaunch",pos+Vector3.new(0,4,0),"FlightLaunch",{District=v[1]})
	end
	local arena=folder(h,"PvPArena");arena:SetAttribute("PvPEnabled",false);arena:SetAttribute("IntegrationId","VoluntaryArena")
	local ac=origin+Vector3.new(350,8,0)
	part(arena,"Bridge",Vector3.new(100,3,18),origin+Vector3.new(260,7,0),C.Wood,Enum.Material.Wood)
	cylinder(arena,"ArenaFloor",190,5,ac,Color3.fromRGB(79,119,154))
	sign(arena,"AIR DUELS • FUTURE / OPT-IN",ac+Vector3.new(0,15,-70),C.Road,85)
	for i=1,6 do
		local a=i*math.pi/3;local pos=ac+Vector3.new(math.cos(a)*88,0,math.sin(a)*88)
		part(arena,"ArenaPillar",Vector3.new(5,100,5),pos+Vector3.new(0,50,0),C.Road)
		part(arena,"SpectatorPerch",Vector3.new(22,2,14),pos+Vector3.new(0,25+(i%3)*18,0),C.Gold)
	end
	for i=1,3 do
		local ring=cylinder(arena,"FlightHoop",28,2,ac+Vector3.new((i-2)*42,30+i*20,0),C.Gold,false)
		ring.Transparency=0.6 -- Temporary guide volumes, safe to fly through.
	end
	marker(arena,"ArenaVolume",ac+Vector3.new(0,55,0),"FuturePvPArena",{Enabled=false,Width=190,Height=110})
	return h
end

function Builder.Build(world)
	local generated=world:FindFirstChild("City")
	if world:GetAttribute("WorldVersion")==WorldConfig.Version and generated and generated:FindFirstChild("Downtown") then return world end
	-- Archive legacy generated city rather than scaling it or touching gameplay scripts.
	if generated then
		local archive=game.ServerStorage:FindFirstChild("WorldArchives") or Instance.new("Folder");archive.Name="WorldArchives";archive.Parent=game.ServerStorage
		generated.Name="City_PreWorldV2";generated.Parent=archive
	end
	for _,name in ipairs({"Hub","Gameplay"}) do local old=world:FindFirstChild(name);if old then old:Destroy() end end
	local city=folder(world,"City");local infrastructure=folder(city,"Infrastructure")
	part(infrastructure,"CityIsland",Vector3.new(WorldConfig.Width,14,WorldConfig.Width),Vector3.new(0,-7,0),C.Grass,Enum.Material.Grass)
	local sea=part(infrastructure,"DistantWater",Vector3.new(2040,8,2040),Vector3.new(0,-18,0),Color3.fromRGB(85,155,184),Enum.Material.SmoothPlastic,nil,false);sea.CanQuery=false
	local gameplay=folder(world,"Gameplay")
	local g={};for _,name in ipairs({"NPCSpawns","AnimalControlSpawns","DogSpawns","FoodSpawns","WaterSpawns","ReturnPerches"}) do g[name]=folder(gameplay,name) end
	for _,name in ipairs(WorldConfig.DistrictOrder) do
		local d=WorldConfig.Districts[name];local f=folder(city,name);f:SetAttribute("District",name);f:SetAttribute("Center",d.Center)
		marker(g.AnimalControlSpawns,name.."Catcher",d.Center+Vector3.new(35,0,40),"AnimalControlSpawn",{District=name})
		local perch=model(g.ReturnPerches,name.."ReturnPerch");local pos=d.Center+Vector3.new(55,2,70)
		perch.PrimaryPart=part(perch,"Pad",Vector3.new(18,2,18),pos,Color3.fromRGB(66,168,147));sign(perch,"RETURN TO NEST",pos+Vector3.new(0,8,0),Color3.fromRGB(50,130,115),22)
		marker(perch,"Interaction",pos+Vector3.new(0,3,0),"ReturnToHub",{District=name})
	end
	road(infrastructure,"WestBoulevard",Vector3.new(-300,0,0),1560,56,false)
	road(infrastructure,"EastBoulevard",Vector3.new(300,0,0),1560,56,false)
	road(infrastructure,"CrossCityBoulevard",Vector3.new(0,0,80),1560,56,true)
	road(infrastructure,"NorthRingRoad",Vector3.new(0,0,-620),1560,42,true)
	road(infrastructure,"SouthRingRoad",Vector3.new(0,0,650),1560,42,true)
	local aviator=model(infrastructure,"AviatorPlaza")
	cylinder(aviator,"Plaza",200,1,Vector3.new(0,0.7,365),C.Walk)
	cylinder(aviator,"FountainBasin",44,2,Vector3.new(0,2,365),C.Glass)
	part(aviator,"FountainColumn",Vector3.new(8,28,8),Vector3.new(0,16,365),C.Gold)
	for i=1,4 do
		local angle=i*math.pi/2;local pos=Vector3.new(math.cos(angle)*70,0,365+math.sin(angle)*70)
		part(aviator,"PerchPillar",Vector3.new(6,18+i*12,6),pos+Vector3.new(0,(18+i*12)/2,0),C.Road)
		part(aviator,"FlightPerch",Vector3.new(24,2,18),pos+Vector3.new(0,19+i*12,0),C.Gold)
		bench(aviator,pos+Vector3.new(0,0,12))
	end
	part(aviator,"ParkConnector",Vector3.new(235,0.5,14),Vector3.new(-190,0.4,365),C.Walk)
	part(aviator,"MarketConnector",Vector3.new(235,0.5,14),Vector3.new(190,0.4,365),C.Walk)
	sign(aviator,"AVIATOR PLAZA",Vector3.new(0,12,280),C.Road,58)
	marker(g.WaterSpawns,"PlazaWater",Vector3.new(0,4,345),"WaterSpawn",{FoodType="Water",District="Downtown"})
	local downtown=city.Downtown
	for _,x in ipairs({-90,90}) do road(downtown,"DowntownStreet",Vector3.new(x,0,-260),520,42,false) end
	for _,z in ipairs({-350,-170}) do road(downtown,"DowntownStreet",Vector3.new(0,0,z),520,42,true) end
	local palettes={Color3.fromRGB(169,186,195),Color3.fromRGB(126,163,187),Color3.fromRGB(209,193,172),Color3.fromRGB(153,175,185)}
	local index=0
	for _,x in ipairs({-180,0,180}) do for _,z in ipairs({-440,-260,-80}) do
		index+=1
		if not (x==0 and z==-260) then
			local height=110+(index*31)%115;if x==0 and z==-440 then height=265 end
			building(downtown,"Skyline_"..index,Vector3.new(x,0,z),105,112,height,palettes[(index-1)%4+1],"Tower",g)
		end
	end end
	cylinder(downtown,"ClockPlaza",95,1,Vector3.new(0,0.7,-260),C.Walk)
	for _,x in ipairs({-255,255}) do
		building(downtown,"AlleyServiceWing_"..x,Vector3.new(x,0,-80),30,80,50,Color3.fromRGB(182,155,132),"Shop",g)
		-- 7.5-stud gaps beside the main towers form deliberate low-flight alley runs.
		sign(downtown,"ALLEY RUN",Vector3.new(x<0 and -236 or 236,12,-127),C.Road,16)
	end
	part(downtown,"ClockTower",Vector3.new(28,120,28),Vector3.new(0,60,-260),C.Earth,Enum.Material.Brick)
	part(downtown,"ClockCrown",Vector3.new(35,8,35),Vector3.new(0,124,-260),C.Gold)
	sign(downtown,"DOWNTOWN",Vector3.new(0,100,-275),C.Road,28)
	local residential=city.Residential
	for row=1,3 do for col=1,4 do
		local pos=Vector3.new(-745+(col-1)*125,0,-460+(row-1)*185)
		part(residential,"Garden",Vector3.new(95,0.4,132),pos+Vector3.new(0,0.2,8),Color3.fromRGB(94,166,107),Enum.Material.Grass)
		building(residential,"House_"..row.."_"..col,pos,56,64,28+((row+col)%3)*8,Color3.fromRGB(230,172+(col%2)*25,128),"House",g)
		tree(residential,pos+Vector3.new(34,0,44),0.75)
	end end
	for _,z in ipairs({-370,-185}) do road(residential,"GardenStreet",Vector3.new(-550,0,z),470,32,true) end
	local commercial=city.Commercial
	for row=1,3 do for col=1,3 do
		local pos=Vector3.new(405+(col-1)*145,0,-450+(row-1)*185)
		local m=building(commercial,"MarketBlock_"..row.."_"..col,pos,92,105,42+((row*col)%3)*22,Color3.fromRGB(221,135+col*12,109),"Shop",g)
		sign(m,({"BREAD & CRUMBS","SUNNY FRIES","ROOFTOP CAFE"})[col],pos+Vector3.new(0,17,-53),C.Road,65)
		part(m,"Awning",Vector3.new(78,2,12),pos+Vector3.new(0,12,-57),C.Gold)
	end end
	for _,z in ipairs({-360,-175}) do road(commercial,"MarketStreet",Vector3.new(550,0,z),470,40,true) end
	part(commercial,"MarketParking",Vector3.new(200,0.3,50),Vector3.new(550,0.4,22),C.Road,Enum.Material.Asphalt)
	local park=city.Park
	part(park,"ParkMeadow",Vector3.new(570,0.5,530),Vector3.new(-480,0.25,375),Color3.fromRGB(87,173,103),Enum.Material.Grass)
	part(park,"PondBank",Vector3.new(175,2,130),Vector3.new(-535,0,410),C.Earth,nil,Enum.PartType.Ball)
	local pond=part(park,"Pond",Vector3.new(155,1,112),Vector3.new(-535,1.2,410),Color3.fromRGB(82,187,208),nil,Enum.PartType.Cylinder,false);pond.CFrame=CFrame.new(pond.Position)*CFrame.Angles(0,0,math.pi/2);pond.Size=Vector3.new(1,155,112)
	part(park,"PondBridge",Vector3.new(15,3,150),Vector3.new(-535,3,410),C.Wood,Enum.Material.Wood)
	part(park,"ParkPath",Vector3.new(540,0.8,14),Vector3.new(-480,0.6,255),C.Walk)
	part(park,"LookoutTower",Vector3.new(8,74,8),Vector3.new(-690,37,500),C.Wood,Enum.Material.Wood)
	part(park,"LookoutDeck",Vector3.new(42,3,42),Vector3.new(-690,76,500),C.Gold)
	sign(park,"CRUMBLE PARK",Vector3.new(-480,17,155),Color3.fromRGB(48,120,80),70)
	for i=1,20 do local x=-735+((i*83)%500);local z=170+((i*137)%420);if math.abs(x+535)>110 or math.abs(z-410)>85 then tree(park,Vector3.new(x,0,z),0.85+(i%3)*0.15) end end
	for i=1,5 do bench(park,Vector3.new(-720+i*85,0,238)) end
	local industrial=city.Industrial
	for row=1,2 do for col=1,3 do
		local pos=Vector3.new(355+(col-1)*170,0,235+(row-1)*240)
		building(industrial,"Warehouse_"..row.."_"..col,pos,126,150,45+col*10,Color3.fromRGB(144,161,160),"Warehouse",g)
		for i=1,2 do part(industrial,"ShippingContainer",Vector3.new(28,12,12),pos+Vector3.new(-35+i*32,6,95),i==1 and Color3.fromRGB(195,118,67) or Color3.fromRGB(74,147,172),Enum.Material.Metal) end
	end end
	road(industrial,"FreightStreet",Vector3.new(490,0,360),580,44,true)
	local depot=building(industrial,"AnimalControlDepot",Vector3.new(115,0,455),80,90,48,Color3.fromRGB(66,155,132),"Shop",g)
	sign(depot,"BIRD CATCHERS",Vector3.new(115,20,409),C.Road,60)
	for _,x in ipairs({735,775}) do cylinder(industrial,"Silo",24,110,Vector3.new(x,55,555),C.Walk) end
	local outskirts=city.Outskirts
	for i=1,12 do tree(outskirts,Vector3.new(-750+i*115,0,750+(i%2)*25),1.3) end
	part(outskirts,"FutureTrail",Vector3.new(24,0.5,130),Vector3.new(0,0.4,740),C.Earth)
	sign(outskirts,"WILDERNESS ROUTE • FUTURE",Vector3.new(0,13,790),Color3.fromRGB(66,110,86),90)
	-- Concentrated target routes, rather than random positions inside buildings.
	local routes={
		Downtown={Vector3.new(-90,0,-440),Vector3.new(-90,0,-350),Vector3.new(0,0,-350),Vector3.new(90,0,-350),Vector3.new(90,0,-170),Vector3.new(-90,0,-170)},
		Residential={Vector3.new(-720,0,-370),Vector3.new(-595,0,-370),Vector3.new(-470,0,-370),Vector3.new(-470,0,-185),Vector3.new(-595,0,-185),Vector3.new(-720,0,-185)},
		Commercial={Vector3.new(405,0,-360),Vector3.new(550,0,-360),Vector3.new(695,0,-360),Vector3.new(695,0,-175),Vector3.new(550,0,-175),Vector3.new(405,0,-175)},
		Park={Vector3.new(-720,0,255),Vector3.new(-620,0,255),Vector3.new(-480,0,255),Vector3.new(-360,0,255),Vector3.new(-360,0,535),Vector3.new(-650,0,535)},
		Industrial={Vector3.new(360,0,360),Vector3.new(490,0,360),Vector3.new(650,0,360),Vector3.new(760,0,360),Vector3.new(760,0,615),Vector3.new(480,0,615)},
		Outskirts={Vector3.new(-80,0,715),Vector3.new(0,0,715),Vector3.new(80,0,715)},
	}
	for district,points in pairs(routes) do
		-- Place catchers and return perches on accessible routes, never inside building lots.
		g.AnimalControlSpawns:FindFirstChild(district.."Catcher").Position=points[math.min(2,#points)]+Vector3.new(0,0,15)
		local returnPerch=g.ReturnPerches:FindFirstChild(district.."ReturnPerch")
		returnPerch:PivotTo(CFrame.new(points[1]+Vector3.new(13,2,0)))
		for i,pos in ipairs(points) do
			marker(g.NPCSpawns,district.."Route_"..i,pos,"NPCSpawn",{District=district,RouteIndex=i})
			marker(i%2==0 and g.WaterSpawns or g.FoodSpawns,district.."Resource_"..i,pos+Vector3.new(13,3,0),i%2==0 and "WaterSpawn" or "FoodSpawn",{FoodType=i%2==0 and "Water" or "Burger",District=district})
		end
		local d=WorldConfig.Districts[district]
		for i=1,d.Dogs do marker(g.DogSpawns,district.."Dog_"..i,points[i*2],"DogSpawn",{District=district}) end
	end
	hub(world)
	world:SetAttribute("Built",true);world:SetAttribute("WorldVersion",WorldConfig.Version);world:SetAttribute("PlayableArea",WorldConfig.Width^2)
	return world
end
return Builder
